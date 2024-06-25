create table if not exists achievements
(
    id    integer not null
        primary key,
    ach0  integer default 0,
    ach1  integer default 0,
    ach2  integer default 0,
    ach3  integer default 0,
    ach4  integer default 0,
    ach5  integer default 0,
    ach6  integer default 0,
    ach7  integer default 0,
    ach8  integer default 0,
    ach9  integer default 0,
    ach10 integer default 0,
    ach11 integer default 0,
    ach12 integer default 0,
    ach13 integer default 0,
    ach14 integer default 0,
    ach15 integer default 0,
    ach16 integer default 0,
    ach17 integer default 0,
    ach18 integer default 0,
    ach19 integer default 0,
    ach20 integer default 0,
    ach21 integer default 0,
    ach22 integer default 0,
    ach23 integer default 0,
    ach24 integer default 0,
    ach25 integer default 0,
    ach26 integer default 0,
    ach27 integer default 0,
    ach28 integer default 0,
    ach29 integer default 0,
    ach30 integer default 0,
    ach31 integer default 0,
    ach32 integer default 0
);

alter table achievements
    owner to postgres;

create table if not exists cafe_accepted
(
    cafe_id      integer not null,
    character_id integer not null
);

alter table cafe_accepted
    owner to postgres;

create table if not exists cafebonus
(
    id        serial
        primary key,
    time_req  integer not null,
    item_type integer not null,
    item_id   integer not null,
    quantity  integer not null
);

alter table cafebonus
    owner to postgres;

create table if not exists distribution
(
    id               serial
        primary key,
    character_id     integer,
    type             integer                                          not null,
    deadline         timestamp with time zone,
    event_name       text    default 'GM Gift!'::text                 not null,
    description      text    default '~C05You received a gift!'::text not null,
    times_acceptable integer default 1                                not null,
    min_hr           integer default 65535                            not null,
    max_hr           integer default 65535                            not null,
    min_sr           integer default 65535                            not null,
    max_sr           integer default 65535                            not null,
    min_gr           integer default 65535                            not null,
    max_gr           integer default 65535                            not null,
    data             bytea                                            not null,
    seed             text
);

alter table distribution
    owner to postgres;

create table if not exists distributions_accepted
(
    distribution_id integer,
    character_id    integer
);

alter table distributions_accepted
    owner to postgres;

create table if not exists events
(
    id         serial
        primary key,
    event_type event_type                             not null,
    start_time timestamp with time zone default now() not null
);

alter table events
    owner to postgres;

create table if not exists feature_weapon
(
    start_time timestamp with time zone not null,
    featured   integer                  not null
);

alter table feature_weapon
    owner to postgres;

create table if not exists festa_prizes
(
    id        serial
        primary key,
    type      prize_type not null,
    tier      integer    not null,
    souls_req integer    not null,
    item_id   integer    not null,
    num_item  integer    not null
);

alter table festa_prizes
    owner to postgres;

create table if not exists festa_prizes_accepted
(
    prize_id     integer not null,
    character_id integer not null
);

alter table festa_prizes_accepted
    owner to postgres;

create table if not exists festa_registrations
(
    guild_id integer        not null,
    team     festival_color not null
);

alter table festa_registrations
    owner to postgres;

create table if not exists festa_trials
(
    id         serial
        primary key,
    objective  integer           not null,
    goal_id    integer           not null,
    times_req  integer           not null,
    locale_req integer default 0 not null,
    reward     integer           not null
);

alter table festa_trials
    owner to postgres;

create table if not exists fpoint_items
(
    id        serial
        primary key,
    item_type integer not null,
    item_id   integer not null,
    quantity  integer not null,
    fpoints   integer not null,
    buyable   boolean not null
);

alter table fpoint_items
    owner to postgres;

create table if not exists gacha_box
(
    gacha_id     integer,
    entry_id     integer,
    character_id integer
);

alter table gacha_box
    owner to postgres;

create table if not exists gacha_entries
(
    id              serial
        primary key,
    gacha_id        integer,
    entry_type      integer,
    item_type       integer,
    item_number     integer,
    item_quantity   integer,
    weight          integer,
    rarity          integer,
    rolls           integer,
    frontier_points integer,
    daily_limit     integer,
    name            text
);

alter table gacha_entries
    owner to postgres;

create table if not exists gacha_items
(
    id        serial
        primary key,
    entry_id  integer,
    item_type integer,
    item_id   integer,
    quantity  integer
);

alter table gacha_items
    owner to postgres;

create table if not exists gacha_shop
(
    id            serial
        primary key,
    min_gr        integer,
    min_hr        integer,
    name          text,
    url_banner    text,
    url_feature   text,
    url_thumbnail text,
    wide          boolean,
    recommended   boolean,
    gacha_type    integer,
    hidden        boolean
);

alter table gacha_shop
    owner to postgres;

create table if not exists gacha_stepup
(
    gacha_id     integer,
    step         integer,
    character_id integer
);

alter table gacha_stepup
    owner to postgres;

create table if not exists goocoo
(
    id      integer default nextval('gook_id_seq'::regclass) not null
        constraint gook_pkey
            primary key,
    goocoo0 bytea,
    goocoo1 bytea,
    goocoo2 bytea,
    goocoo3 bytea,
    goocoo4 bytea
);

alter table goocoo
    owner to postgres;

create table if not exists guild_adventures
(
    id           serial
        primary key,
    guild_id     integer                  not null,
    destination  integer                  not null,
    charge       integer default 0        not null,
    depart       integer                  not null,
    return       integer                  not null,
    collected_by text    default ''::text not null
);

alter table guild_adventures
    owner to postgres;

create table if not exists guild_alliances
(
    id         serial
        primary key,
    name       varchar(24)                            not null,
    created_at timestamp with time zone default now() not null,
    parent_id  integer                                not null,
    sub1_id    integer,
    sub2_id    integer
);

alter table guild_alliances
    owner to postgres;

create table if not exists guild_hunts
(
    id          serial
        primary key,
    guild_id    integer                                not null,
    host_id     integer                                not null,
    destination integer                                not null,
    level       integer                                not null,
    acquired    boolean                  default false not null,
    collected   boolean                  default false not null,
    hunt_data   bytea                                  not null,
    cats_used   text                                   not null,
    start       timestamp with time zone default now() not null
);

alter table guild_hunts
    owner to postgres;

create table if not exists guild_meals
(
    id         serial
        primary key,
    guild_id   integer not null,
    meal_id    integer not null,
    level      integer not null,
    created_at timestamp with time zone
);

alter table guild_meals
    owner to postgres;

create table if not exists guild_posts
(
    id         serial
        primary key,
    guild_id   integer                                   not null,
    author_id  integer                                   not null,
    post_type  integer                                   not null,
    stamp_id   integer                                   not null,
    title      text                                      not null,
    body       text                                      not null,
    created_at timestamp with time zone default now()    not null,
    liked_by   text                     default ''::text not null
);

alter table guild_posts
    owner to postgres;

create table if not exists guilds
(
    id                 serial
        primary key,
    name               varchar(24),
    created_at         timestamp with time zone default now(),
    leader_id          integer                                                not null,
    main_motto         integer                  default 0,
    rank_rp            integer                  default 0                     not null,
    comment            varchar(255)             default ''::character varying not null,
    icon               bytea,
    sub_motto          integer                  default 0,
    item_box           bytea,
    event_rp           integer                  default 0                     not null,
    pugi_name_1        varchar(12)              default ''::character varying,
    pugi_name_2        varchar(12)              default ''::character varying,
    pugi_name_3        varchar(12)              default ''::character varying,
    recruiting         boolean                  default true                  not null,
    pugi_outfit_1      integer                  default 0                     not null,
    pugi_outfit_2      integer                  default 0                     not null,
    pugi_outfit_3      integer                  default 0                     not null,
    pugi_outfits       integer                  default 0                     not null,
    tower_mission_page integer                  default 1,
    tower_rp           integer                  default 0,
    room_rp            integer                  default 0,
    room_expiry        timestamp
);

alter table guilds
    owner to postgres;

create table if not exists login_boost
(
    char_id    integer,
    week_req   integer,
    expiration timestamp with time zone,
    reset      timestamp with time zone
);

alter table login_boost
    owner to postgres;

create table if not exists rengoku_score
(
    character_id  integer not null
        primary key,
    max_stages_mp integer,
    max_points_mp integer,
    max_stages_sp integer,
    max_points_sp integer
);

alter table rengoku_score
    owner to postgres;

create table if not exists servers
(
    server_id         integer not null,
    current_players   integer not null,
    world_name        text,
    world_description text,
    land              integer
);

alter table servers
    owner to postgres;

create table if not exists shop_items
(
    shop_type    integer,
    shop_id      integer,
    id           integer default nextval('shop_items_id_seq'::regclass) not null
        primary key,
    item_id      uint16,
    cost         integer,
    quantity     uint16,
    min_hr       uint16,
    min_sr       uint16,
    min_gr       uint16,
    store_level  uint16,
    max_quantity uint16,
    road_floors  uint16,
    road_fatalis uint16
);

alter table shop_items
    owner to postgres;

create table if not exists shop_items_bought
(
    character_id integer,
    shop_item_id integer,
    bought       integer
);

alter table shop_items_bought
    owner to postgres;

create table if not exists sign_sessions
(
    user_id   integer,
    char_id   integer,
    token     varchar(16) not null,
    server_id integer,
    id        serial
        primary key,
    psn_id    text
);

alter table sign_sessions
    owner to postgres;

create table if not exists stamps
(
    character_id integer not null
        primary key,
    hl_total     integer default 0,
    hl_redeemed  integer default 0,
    hl_checked   timestamp with time zone,
    ex_total     integer default 0,
    ex_redeemed  integer default 0,
    ex_checked   timestamp with time zone
);

alter table stamps
    owner to postgres;

create table if not exists titles
(
    id          integer not null,
    char_id     integer not null,
    unlocked_at timestamp with time zone,
    updated_at  timestamp with time zone
);

alter table titles
    owner to postgres;

create table if not exists user_binary
(
    id              serial
        primary key,
    type2           bytea,
    type3           bytea,
    house_tier      bytea,
    house_state     integer,
    house_password  text,
    house_data      bytea,
    house_furniture bytea,
    bookshelf       bytea,
    gallery         bytea,
    tore            bytea,
    garden          bytea,
    mission         bytea
);

alter table user_binary
    owner to postgres;

create table if not exists users
(
    id              serial
        primary key,
    username        text               not null
        unique,
    password        text               not null,
    item_box        bytea,
    rights          integer default 12 not null,
    last_character  integer default 0,
    last_login      timestamp with time zone,
    return_expires  timestamp with time zone,
    gacha_premium   integer,
    gacha_trial     integer,
    frontier_points integer,
    psn_id          text,
    wiiu_key        text,
    discord_token   text,
    discord_id      text,
    op              boolean,
    timer           boolean,
    seed            text
);

alter table users
    owner to postgres;

create table if not exists characters
(
    id                   serial
        primary key,
    user_id              bigint
        references users,
    is_female            boolean,
    is_new_character     boolean,
    name                 varchar(15),
    unk_desc_string      varchar(31),
    gr                   uint16,
    hr                   uint16,
    weapon_type          uint16,
    last_login           integer,
    savedata             bytea,
    decomyset            bytea,
    hunternavi           bytea,
    otomoairou           bytea,
    partner              bytea,
    platebox             bytea,
    platedata            bytea,
    platemyset           bytea,
    rengokudata          bytea,
    savemercenary        bytea,
    restrict_guild_scout boolean                  default false    not null,
    minidata             bytea,
    gacha_items          bytea,
    daily_time           timestamp with time zone,
    house_info           bytea,
    login_boost          bytea,
    skin_hist            bytea,
    kouryou_point        integer,
    gcp                  integer,
    guild_post_checked   timestamp with time zone default now()    not null,
    time_played          integer                  default 0        not null,
    weapon_id            integer                  default 0        not null,
    scenariodata         bytea,
    savefavoritequest    bytea,
    friends              text                     default ''::text not null,
    blocked              text                     default ''::text not null,
    deleted              boolean                  default false    not null,
    cafe_time            integer                  default 0,
    netcafe_points       integer                  default 0,
    boost_time           timestamp with time zone,
    cafe_reset           timestamp with time zone,
    bonus_quests         integer                  default 0        not null,
    daily_quests         integer                  default 0        not null,
    promo_points         integer                  default 0        not null,
    rasta_id             integer,
    pact_id              integer,
    stampcard            integer                  default 0        not null,
    mezfes               bytea,
    seed                 text
);

alter table characters
    owner to postgres;

create table if not exists guild_applications
(
    id               serial
        primary key,
    guild_id         integer                                not null
        references guilds,
    character_id     integer                                not null
        references characters,
    actor_id         integer                                not null
        references characters,
    application_type guild_application_type                 not null,
    created_at       timestamp with time zone default now() not null,
    constraint guild_application_character_id
        unique (guild_id, character_id)
);

alter table guild_applications
    owner to postgres;

create index if not exists guild_application_type_index
    on guild_applications (application_type);

create table if not exists guild_characters
(
    id               serial
        primary key,
    guild_id         bigint
        references guilds,
    character_id     bigint
        references characters,
    joined_at        timestamp with time zone default now(),
    avoid_leadership boolean                  default false not null,
    order_index      integer                  default 1     not null,
    recruiter        boolean                  default false not null,
    rp_today         integer                  default 0,
    rp_yesterday     integer                  default 0,
    tower_mission_1  integer,
    tower_mission_2  integer,
    tower_mission_3  integer,
    box_claimed      timestamp with time zone default now(),
    treasure_hunt    integer,
    trial_vote       integer
);

alter table guild_characters
    owner to postgres;

create unique index if not exists guild_character_unique_index
    on guild_characters (character_id);

create table if not exists mail
(
    id                     serial
        primary key,
    sender_id              integer                                                not null
        references characters,
    recipient_id           integer                                                not null
        references characters,
    subject                varchar                  default ''::character varying not null,
    body                   varchar                  default ''::character varying not null,
    read                   boolean                  default false                 not null,
    attached_item_received boolean                  default false                 not null,
    attached_item          integer,
    attached_item_amount   integer                  default 1                     not null,
    is_guild_invite        boolean                  default false                 not null,
    created_at             timestamp with time zone default now()                 not null,
    deleted                boolean                  default false                 not null,
    locked                 boolean                  default false                 not null
);

alter table mail
    owner to postgres;

create index if not exists mail_recipient_deleted_created_id_index
    on mail (recipient_id asc, deleted asc, created_at desc, id desc);

create table if not exists warehouse
(
    character_id integer not null
        primary key,
    item0        bytea,
    item1        bytea,
    item2        bytea,
    item3        bytea,
    item4        bytea,
    item5        bytea,
    item6        bytea,
    item7        bytea,
    item8        bytea,
    item9        bytea,
    item10       bytea,
    item0name    text,
    item1name    text,
    item2name    text,
    item3name    text,
    item4name    text,
    item5name    text,
    item6name    text,
    item7name    text,
    item8name    text,
    item9name    text,
    equip0       bytea,
    equip1       bytea,
    equip2       bytea,
    equip3       bytea,
    equip4       bytea,
    equip5       bytea,
    equip6       bytea,
    equip7       bytea,
    equip8       bytea,
    equip9       bytea,
    equip10      bytea,
    equip0name   text,
    equip1name   text,
    equip2name   text,
    equip3name   text,
    equip4name   text,
    equip5name   text,
    equip6name   text,
    equip7name   text,
    equip8name   text,
    equip9name   text
);

alter table warehouse
    owner to postgres;

create table if not exists tower
(
    char_id integer,
    tr      integer,
    trp     integer,
    tsp     integer,
    block1  integer,
    block2  integer,
    skills  text default '0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0'::text,
    gems    text default '0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0'::text
);

alter table tower
    owner to postgres;

create table if not exists event_quests
(
    id            serial
        primary key,
    max_players   integer,
    quest_type    integer                                not null,
    quest_id      integer                                not null,
    mark          integer,
    flags         integer,
    start_time    timestamp with time zone default now() not null,
    active_days   integer,
    inactive_days integer
);

alter table event_quests
    owner to postgres;

create table if not exists trend_weapons
(
    weapon_id   integer not null
        primary key,
    weapon_type integer not null,
    count       integer default 0
);

alter table trend_weapons
    owner to postgres;

create table if not exists scenario_counter
(
    id          serial
        primary key,
    scenario_id numeric not null,
    category_id numeric not null
);

alter table scenario_counter
    owner to postgres;

create table if not exists kill_logs
(
    id           serial
        primary key,
    character_id integer                  not null,
    monster      integer                  not null,
    quantity     integer                  not null,
    timestamp    timestamp with time zone not null,
    quest_id     text
);

alter table kill_logs
    owner to postgres;

create table if not exists guild_hunts_claimed
(
    hunt_id      integer not null,
    character_id integer not null
);

alter table guild_hunts_claimed
    owner to postgres;

create table if not exists distribution_items
(
    id              serial
        primary key,
    distribution_id integer not null,
    item_type       integer not null,
    item_id         integer,
    quantity        integer
);

alter table distribution_items
    owner to postgres;

create table if not exists bans
(
    user_id integer not null
        primary key,
    expires timestamp with time zone
);

alter table bans
    owner to postgres;

create table if not exists festa_submissions
(
    character_id integer                  not null,
    guild_id     integer                  not null,
    trial_type   integer                  not null,
    souls        integer                  not null,
    timestamp    timestamp with time zone not null
);

alter table festa_submissions
    owner to postgres;

create table if not exists tune_values
(
    hrp_multiplier           double precision default 1.0 not null,
    hrp_multiplier_nc        double precision default 1.0 not null,
    srp_multiplier           double precision default 1.0 not null,
    srp_multiplier_nc        double precision default 1.0 not null,
    grp_multiplier           double precision default 1.0 not null,
    grp_multiplier_nc        double precision default 1.0 not null,
    zenny_multiplier         double precision default 1.0 not null,
    zenny_multiplier_nc      double precision default 1.0 not null,
    material_multiplier      double precision default 1.0 not null,
    material_multiplier_nc   double precision default 1.0 not null,
    g_material_multiplier    double precision default 1.0 not null,
    g_material_multiplier_nc double precision default 1.0 not null,
    gcp_multiplier           double precision default 1.0 not null,
    g_urgent_rate            double precision default 1.0 not null,
    gsrp_multiplier          double precision default 1.0 not null,
    gsrp_multiplier_nc       double precision default 1.0 not null,
    gzenny_multiplier        double precision default 1.0 not null,
    gzenny_multiplier_nc     double precision default 1.0 not null,
    extra_carves             integer          default 0   not null,
    extra_carves_nc          integer          default 0   not null
);

alter table tune_values
    owner to postgres;

create table if not exists archi_index
(
    seed  text              not null,
    index integer default 0 not null
);

alter table archi_index
    owner to postgres;


