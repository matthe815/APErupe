package main

import (
	"encoding/hex"
	"erupe-ce/common/byteframe"
	_config "erupe-ce/config"
	"fmt"
	"io"
	"math"
	"math/rand"
	"net"
	"os"
	"os/signal"
	"runtime/debug"
	"strconv"
	"syscall"
	"time"

	"erupe-ce/server/api"
	"erupe-ce/server/channelserver"
	"erupe-ce/server/discordbot"
	"erupe-ce/server/entranceserver"
	"erupe-ce/server/signserver"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
	"go.uber.org/zap"
)

// Temporary DB auto clean on startup for quick development & testing.
func cleanDB(db *sqlx.DB) {
	_ = db.MustExec("DELETE FROM guild_characters")
	_ = db.MustExec("DELETE FROM guilds")
	_ = db.MustExec("DELETE FROM characters")
	_ = db.MustExec("DELETE FROM users")
}

var Commit = func() string {
	if info, ok := debug.ReadBuildInfo(); ok {
		for _, setting := range info.Settings {
			if setting.Key == "vcs.revision" {
				return setting.Value[:7]
			}
		}
	}
	return "unknown"
}

func main() {
	var err error

	var zapLogger *zap.Logger
	config := _config.ErupeConfig
	zapLogger, _ = zap.NewDevelopment()

	defer zapLogger.Sync()
	logger := zapLogger.Named("main")

	logger.Info(fmt.Sprintf("Starting Erupe (9.3b-%s)", Commit()))
	logger.Info(fmt.Sprintf("Client Mode: %s (%d)", config.ClientMode, config.RealClientMode))

	if config.Database.Password == "" {
		preventClose("Database password is blank")
	}

	if net.ParseIP(config.Host) == nil {
		ips, _ := net.LookupIP(config.Host)
		for _, ip := range ips {
			if ip != nil {
				config.Host = ip.String()
				break
			}
		}
		if net.ParseIP(config.Host) == nil {
			preventClose("Invalid host address")
		}
	}

	// Discord bot
	var discordBot *discordbot.DiscordBot = nil

	if config.Discord.Enabled {
		bot, err := discordbot.NewDiscordBot(discordbot.Options{
			Logger: logger,
			Config: _config.ErupeConfig,
		})

		if err != nil {
			preventClose(fmt.Sprintf("Discord: Failed to start, %s", err.Error()))
		}

		// Discord bot
		err = bot.Start()

		if err != nil {
			preventClose(fmt.Sprintf("Discord: Failed to start, %s", err.Error()))
		}

		discordBot = bot

		_, err = discordBot.Session.ApplicationCommandBulkOverwrite(discordBot.Session.State.User.ID, "", discordbot.Commands)
		if err != nil {
			preventClose(fmt.Sprintf("Discord: Failed to start, %s", err.Error()))
		}

		logger.Info("Discord: Started successfully")
	} else {
		logger.Info("Discord: Disabled")
	}

	// Create the postgres DB pool.
	connectString := fmt.Sprintf(
		"host='%s' port='%d' user='%s' password='%s' dbname='%s' sslmode=disable",
		config.Database.Host,
		config.Database.Port,
		config.Database.User,
		config.Database.Password,
		config.Database.Database,
	)

	db, err := sqlx.Open("postgres", connectString)
	if err != nil {
		preventClose(fmt.Sprintf("Database: Failed to open, %s", err.Error()))
	}

	// Test the DB connection.
	err = db.Ping()
	if err != nil {
		preventClose(fmt.Sprintf("Database: Failed to ping, %s", err.Error()))
	}
	logger.Info("Database: Started successfully")

	// Clear stale data
	if config.DebugOptions.ProxyPort == 0 {
		_ = db.MustExec("DELETE FROM sign_sessions")
	}
	_ = db.MustExec("DELETE FROM servers")
	_ = db.MustExec(`UPDATE guild_characters SET treasure_hunt=NULL`)

	// Clean the DB if the option is on.
	if config.DebugOptions.CleanDB {
		logger.Info("Database: Started clearing...")
		cleanDB(db)
		logger.Info("Database: Finished clearing")
	}

	logger.Info(fmt.Sprintf("Server Time: %s", channelserver.TimeAdjusted().String()))

	// Now start our server(s).

	// Entrance server.

	var entranceServer *entranceserver.Server
	if config.Entrance.Enabled {
		entranceServer = entranceserver.NewServer(
			&entranceserver.Config{
				Logger:      logger.Named("entrance"),
				ErupeConfig: _config.ErupeConfig,
				DB:          db,
			})
		err = entranceServer.Start()
		if err != nil {
			preventClose(fmt.Sprintf("Entrance: Failed to start, %s", err.Error()))
		}
		logger.Info("Entrance: Started successfully")
	} else {
		logger.Info("Entrance: Disabled")
	}

	// Sign server.

	var signServer *signserver.Server
	if config.Sign.Enabled {
		signServer = signserver.NewServer(
			&signserver.Config{
				Logger:      logger.Named("sign"),
				ErupeConfig: _config.ErupeConfig,
				DB:          db,
			})
		err = signServer.Start()
		if err != nil {
			preventClose(fmt.Sprintf("Sign: Failed to start, %s", err.Error()))
		}
		logger.Info("Sign: Started successfully")
	} else {
		logger.Info("Sign: Disabled")
	}

	// New Sign server
	var ApiServer *api.APIServer
	if config.API.Enabled {
		ApiServer = api.NewAPIServer(
			&api.Config{
				Logger:      logger.Named("sign"),
				ErupeConfig: _config.ErupeConfig,
				DB:          db,
			})
		err = ApiServer.Start()
		if err != nil {
			preventClose(fmt.Sprintf("API: Failed to start, %s", err.Error()))
		}
		logger.Info("API: Started successfully")
	} else {
		logger.Info("API: Disabled")
	}

	var channels []*channelserver.Server

	archi := startArchipelago(channels, db)
	signServer.Archipelago = archi

	if archi == nil {
		if config.Sign.Enabled {
			signServer.Shutdown()
		}

		if config.API.Enabled {
			ApiServer.Shutdown()
		}

		if config.Entrance.Enabled {
			entranceServer.Shutdown()
		}

		panic("Couldn't connect to Archipelago Connector.")
	}

	if config.Channel.Enabled {
		channelQuery := ""
		si := 0
		ci := 0
		count := 1
		for j, ee := range config.Entrance.Entries {
			for i, ce := range ee.Channels {
				sid := (4096 + si*256) + (16 + ci)
				c := *channelserver.NewServer(&channelserver.Config{
					ID:          uint16(sid),
					Logger:      logger.Named("channel-" + fmt.Sprint(count)),
					ErupeConfig: _config.ErupeConfig,
					DB:          db,
					DiscordBot:  discordBot,
				})
				if ee.IP == "" {
					c.IP = config.Host
				} else {
					c.IP = ee.IP
				}
				c.Port = ce.Port
				c.GlobalID = fmt.Sprintf("%02d%02d", j+1, i+1)
				c.Archipelago = archi
				err = c.Start()
				if err != nil {
					preventClose(fmt.Sprintf("Channel: Failed to start, %s", err.Error()))
				} else {
					channelQuery += fmt.Sprintf(`INSERT INTO servers (server_id, current_players, world_name, world_description, land) VALUES (%d, 0, '%s', '%s', %d);`, sid, ee.Name, ee.Description, i+1)
					channels = append(channels, &c)
					logger.Info(fmt.Sprintf("Channel %d (%d): Started successfully", count, ce.Port))
					ci++
					count++
				}
			}
			ci = 0
			si++
		}

		// Register all servers in DB
		_ = db.MustExec(channelQuery)

		for _, c := range channels {
			c.Channels = channels
		}
	}

	logger.Info("Finished starting Erupe")
	archi.Channels = channels

	// Wait for exit or interrupt with ctrl+C.
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	<-c

	if !config.DisableSoftCrash {
		for i := 0; i < 10; i++ {
			message := fmt.Sprintf("Shutting down in %d...", 10-i)
			for _, c := range channels {
				c.BroadcastChatMessage(message)
			}
			logger.Info(message)
			time.Sleep(time.Second)
		}
	}

	if config.Channel.Enabled {
		for _, c := range channels {
			c.Shutdown()
		}
	}

	if config.Sign.Enabled {
		signServer.Shutdown()
	}

	if config.API.Enabled {
		ApiServer.Shutdown()
	}

	if config.Entrance.Enabled {
		entranceServer.Shutdown()
	}

	archi.Connector.Close()

	time.Sleep(1 * time.Second)
}

func wait() {
	for {
		time.Sleep(time.Millisecond * 100)
	}
}

func startArchipelago(channels []*channelserver.Server, db *sqlx.DB) *channelserver.ArchipelagoConnector {
	conn, err := net.Dial("tcp", "localhost:3000")
	if err != nil {
		fmt.Println("Failed to connect to Archipelago Connector")
		return nil
	}

	archi := &channelserver.ArchipelagoConnector{
		Connector: conn,
		DB:        db,
		Channels:  channels,
	}

	go acceptArchiInput(archi)
	return archi
}

func acceptArchiInput(archi *channelserver.ArchipelagoConnector) {
	for {
		buffer := make([]byte, 300)
		_, err := archi.Connector.Read(buffer)
		if err != nil {
			panic(err)
		}

		if len(buffer) != 0 {
			var bf byteframe.ByteFrame
			bf.WriteBytes(buffer)
			bf.SetLE()
			bf.Seek(0, io.SeekStart)
			fmt.Println(hex.Dump(buffer))

			for bf.Index() < uint(len(buffer)) {
				pktType := bf.ReadUint8()

				switch pktType {
				case 0:
					break
				case 1:
					readArchiIndex(bf.ReadBytes(20), archi)
					fmt.Println("Got seed packet")
					break
				case 2:
					itemIndex := bf.ReadUint32()
					player := string(bf.ReadNullTerminatedBytes())
					dataOffset := bf.ReadUint8()
					itemId := bf.ReadUint16()
					archi.ReceivedItems = append(archi.ReceivedItems, channelserver.ReceivedItem{ItemId: itemId, Player: player, Offset: dataOffset, ItemIndex: itemIndex})
					fmt.Println("Recieved " + strconv.Itoa(int(itemIndex)) + " from " + player)
					break
				case 3:
					processReceipts(archi)
					updateArchiIndex(archi)
					archi.ReceivedItems = make([]channelserver.ReceivedItem, 0)
					break
				case 4:
					// chat message
					chatMessage := string(bf.ReadNullTerminatedBytes())
					fmt.Println("Received chat message: " + chatMessage)
					for _, c := range archi.Channels {
						c.BroadcastChatMessage(chatMessage)
					}
					break
				}
			}
		}
	}
}

func readArchiIndex(initialBuffer []byte, archi *channelserver.ArchipelagoConnector) {
	archi.Seed = string(initialBuffer)
	row := archi.DB.QueryRowx("SELECT * FROM archi_index WHERE seed=$1", string(initialBuffer))

	var seed string
	var index uint8

	err := row.Scan(&seed, &index)
	if err != nil {
		fmt.Println("new game")
	}

	archi.Index = int(index)
}

func updateArchiIndex(archi *channelserver.ArchipelagoConnector) {
	archi.DB.Exec("DELETE FROM archi_index WHERE seed=$1", archi.Seed)
	archi.DB.Exec("INSERT INTO archi_index(seed, index) VALUES($1, $2)", archi.Seed, archi.Index)
}

func grantItem(archi *channelserver.ArchipelagoConnector, name string, item channelserver.ReceivedItem, data string, claimCount uint16) {
	_, err := archi.DB.Exec("INSERT INTO distribution(type, event_name, times_acceptable, description, data, seed) VALUES($1, $2, $3, $4, DECODE($5, 'hex'), $6)", 1, fmt.Sprintf("Gift From the %s Guild", item.Player), claimCount, fmt.Sprintf("We at the %s Guild would\nlike to offer you %s", item.Player, name), data, archi.Seed)
	if err != nil {
		fmt.Println(err)
		return
	}
}

func processReceipts(archi *channelserver.ArchipelagoConnector) {
	if len(archi.ReceivedItems) == 0 || len(archi.ReceivedItems) < archi.Index {
		return
	}

	processQueue := archi.ReceivedItems[archi.Index:]

	for _, value := range processQueue {
		hexData, _ := hex.DecodeString("000107000000010000000100000000")
		bf := byteframe.NewByteFrameFromBytes(hexData)
		bf.SetLE()

		switch value.ItemIndex {
		case 5135230:
			grantItem(archi, "the ~C02HR 1 Urgent Ticket", value, "000107000004B10000000100000000", 99)
			break
		case 5135231:
			grantItem(archi, "the ~C02HR 2 Urgent Ticket", value, "000107000004B20000000100000000", 99)
			break
		case 5135232:
			grantItem(archi, "the ~C02HR 3 Urgent Ticket", value, "000107000004B30000000100000000", 99)
			break
		case 5135233:
			grantItem(archi, "the ~C02HR 4 Urgent Ticket", value, "000107000004B40000000100000000", 99)
			break
		case 5135234:
			grantItem(archi, "the ~C02HR 5 Urgent Ticket", value, "000107000004B50000000100000000", 99)
			break
		case 5135235:
			grantItem(archi, "the ~C02HR 6 Urgent Ticket", value, "000107000004B60000000100000000", 99)
			break
		case 5135236:
			grantItem(archi, "the ~C02HR 7 Urgent Ticket", value, "000107000004B70000000100000000", 99)
			break
		case 5135237:
			grantItem(archi, "50000 ~C10Zenny", value, "00010A000000000000138800000000", 1)
			break
		case 5135238:
			bf.Seek(5, io.SeekStart)
			bf.WriteUint16(value.ItemId)
			bf.Seek(10, io.SeekStart)
			randomQuant := math.Floor(rand.Float64() * 99)
			bf.WriteUint16(uint16(randomQuant))

			grantItem(archi, "a ~C10Random Item", value, hex.EncodeToString(bf.Data()), 1)
			break
		case 5135239: // random weapon
			bf.Seek(2, io.SeekStart)
			bf.WriteUint8(value.Offset)
			bf.Seek(5, io.SeekStart)
			bf.WriteUint16(value.ItemId)
			_, err := archi.DB.Exec("INSERT INTO distribution(type, event_name, description, data, seed) VALUES($1, $2, $3, $4, $5)", 1, fmt.Sprintf("Gift From the %s Guild", value.Player), fmt.Sprintf("We at the %s Guild would like\nto offer you %s", value.Player, "a Random Weapon"), bf.Data(), archi.Seed)
			if err != nil {
				panic(err)
			}
			break
		case 5135240: // random armor
			bf.Seek(2, io.SeekStart)
			bf.WriteUint8(value.Offset)
			bf.Seek(5, io.SeekStart)
			bf.WriteUint16(value.ItemId)
			_, err := archi.DB.Exec("INSERT INTO distribution(type, event_name, description, data, seed) VALUES($1, $2, $3, $4, $5)", 1, fmt.Sprintf("Gift From the %s Guild", value.Player), fmt.Sprintf("We at the %s Guild would like\nto offer you %s", value.Player, "a Random Armor"), bf.Data(), archi.Seed)
			if err != nil {
				panic(err)
			}
			break
		case 5135242:
			archi.DB.Exec("INSERT INTO distribution(type, event_name, description, data, seed) VALUES($1, $2, $3, DECODE($4, 'hex'), $5)", 1, fmt.Sprintf("Gift From the %s Guild", value.Player), fmt.Sprintf("We at the %s Guild would like to\noffer you %s", value.Player, "200 N-Points"), "00011100000000000000C800000000", archi.Seed)
			break
		case 5135243:
			archi.DB.Exec("INSERT INTO distribution(type, event_name, description, data, seed) VALUES($1, $2, $3, DECODE($4, 'hex'), $5)", 1, fmt.Sprintf("Gift From the %s Guild", value.Player), fmt.Sprintf("We at the %s Guild would like to\noffer you %s", value.Player, "10 GCP Tickets"), "000107000027C30000000A00000000", archi.Seed)
			break
		}
		archi.Index++
	}
}

func preventClose(text string) {
	if _config.ErupeConfig.DisableSoftCrash {
		os.Exit(0)
	}
	fmt.Println("\nFailed to start Erupe:\n" + text)
	go wait()
	fmt.Println("\nPress Enter/Return to exit...")
	fmt.Scanln()
	os.Exit(0)
}
