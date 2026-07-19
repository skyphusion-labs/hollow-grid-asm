%ifndef HG_STATE_INC
%define HG_STATE_INC

%define HG_EVT_CONNECTED 1
%define HG_EVT_RECEIVE   2
%define HG_EVT_WRITABLE  3
%define HG_EVT_CLOSED    4

%define HG_LOGIN_NAME 0
%define HG_LOGIN_RACE 1
%define HG_LOGIN_PLAY 2

; --- session layout (one lws per-connection user block) ---
; Keep in lockstep with include/hg_session.h
%define SESSION_STATE        0
%define SESSION_NAME         8      ; 40 bytes (name <= 32 + nul)
%define SESSION_RACE         48     ; 16 bytes
%define SESSION_ROOM         64
%define SESSION_HP           72
%define SESSION_MAX_HP       80
%define SESSION_LEVEL        88
%define SESSION_XP           96
%define SESSION_GOLD         104
%define SESSION_MORALITY     112
%define SESSION_ADDICTION    120
%define SESSION_ASHSWORN     128
%define SESSION_STRAYED      136
%define SESSION_REDEEMED     144
%define SESSION_RESISTED     152
%define SESSION_POISONED     160
%define SESSION_FACTION      168    ; 16 bytes
%define SESSION_POSITION     184    ; 16 bytes
%define SESSION_TITLE        200    ; 48 bytes
%define SESSION_EQ_WEAPON    248    ; 16 bytes each slot (item id or empty)
%define SESSION_EQ_HEAD      264
%define SESSION_EQ_BODY      280
%define SESSION_EQ_HANDS     296
%define SESSION_EQ_FEET      312
%define SESSION_INV_COUNT    328
%define SESSION_INVENTORY    336    ; 16 slots x 16 bytes
%define SESSION_INV_SLOTS    16
%define SESSION_INV_SLOT_SIZE 16
%define SESSION_TARGET       592    ; mob instance index + 1 (0 = none)
%define SESSION_IN_COMBAT    600
%define SESSION_TRAIT_READY  608    ; unix ms when racial ability recharges
%define SESSION_TREAT_READY  616    ; unix ms medic cooldown
%define SESSION_REPLY_TO     624    ; 40 bytes: who last told us
%define SESSION_MKT_RESOLVED 664    ; per-session market join/defend spent
%define SESSION_LAST_GRIDCAST_ID 672
%define SESSION_LAST_FREED   680    ; 40 bytes: first rescued name (dream)
%define SESSION_WSI          720
%define SESSION_LAST_TICK    728
%define SESSION_OUT_LEN      736
%define SESSION_CLOSE        744
%define SESSION_OUT          752
%define SESSION_OUT_CAP      16384
%define SESSION_RX_LEN       17136  ; assembled-message length, -1 = overflowed
%define SESSION_RX           17144  ; WS fragment reassembly buffer
%define SESSION_RX_CAP       256
%define SESSION_SIZE         17400

; Legacy aliases used during the offset rename (map to new names).
%define SESSION_WEAPON           SESSION_EQ_WEAPON
%define SESSION_INVENTORY_COUNT  SESSION_INV_COUNT

%define HG_MAX_SESSIONS 32
%define HG_HEARTBEAT_MS 2000
%define HG_COMBAT_MS    2000

; --- rooms ---
%define ROOM_NEXUS   0
%define ROOM_TAVERN 1
%define ROOM_MARKET 2
%define ROOM_HOLDING_PIT 3
%define ROOM_WORKSHOP 4
%define ROOM_ROOF 5
%define ROOM_TUNNELS 6
%define ROOM_SUMP 7
%define ROOM_FLOODGATE 8
%define ROOM_COLDROW 9
%define ROOM_COOLING 10
%define ROOM_FIBER 11
%define ROOM_CORELAB 12
%define ROOM_ARCHIVE 13
%define ROOM_DUNES 14
%define ROOM_SCORCH_ROAD 15
%define ROOM_WAYSTATION 16
%define ROOM_TRANSIT_HUB 17
%define ROOM_CHECKPOINT 18
%define ROOM_GATE 19
%define ROOM_MUSTER 20
%define ROOM_CELLS 21
%define ROOM_WARROOM 22
%define ROOM_DAIS 23
%define ROOM_RELAY_CUT 24
%define ROOM_HANDOFF_BAY 25
%define ROOM_CUSTODY_LOCK 26
%define ROOM_EAST_REPEATER 27
%define ROOM_COUNT 28

; --- live mob instances (fixed table in combat.asm) ---
%define MOB_ROOM       0
%define MOB_HP         8
%define MOB_MAX_HP     16
%define MOB_DAMAGE     24
%define MOB_XP         32
%define MOB_ALIVE      40
%define MOB_DIED_AT    48   ; unix ms of last death (cleared on respawn)
%define MOB_RESPAWN_MS 56
%define MOB_SLAIN_AT   64   ; unix ms of last death (kept across respawn)
%define MOB_ID         72   ; cstr ptr
%define MOB_NAME       80   ; cstr ptr
%define MOB_DESC       88   ; cstr ptr
%define MOB_REC_SIZE   96

%define MOB_RAT       0
%define MOB_RAIDER    1
%define MOB_WARDEN    2
%define MOB_LEECH     3
%define MOB_ENFORCER  4
%define MOB_TROOPER   5
%define MOB_ZEALOT    6
%define MOB_ASHMONGER 7
%define MOB_CUSTODIAN 8
%define MOB_COUNT     9

; --- item table (content.asm) ---
%define ITEM_ID     0
%define ITEM_NAME   8
%define ITEM_DESC   16
%define ITEM_SLOT   24   ; 0 none, 1 weapon, 2 head, 3 body, 4 hands, 5 feet
%define ITEM_DAMAGE 32
%define ITEM_ARMOR  40
%define ITEM_VALUE  48
%define ITEM_REC_SIZE 56
%define ITEM_COUNT  11

; --- race table (content.asm) ---
%define RACE_ID       0
%define RACE_NAME     8
%define RACE_HUNTED   16
%define RACE_HPMOD    24
%define RACE_DAMAGE   32
%define RACE_ARMOR    40
%define RACE_REGEN    48
%define RACE_AB_VERB  56
%define RACE_AB_NAME  64
%define RACE_COOLDOWN 72
%define RACE_REC_SIZE 80
%define RACE_COUNT    7

; --- deed ledger kinds ---
%define DEED_MENDED    0
%define DEED_FORGAVE   1
%define DEED_AIDED     2
%define DEED_KEPT      3
%define DEED_FREED     4
%define DEED_SHELTERED 5
%define DEED_STOOD     6
%define DEED_INSCRIBED 7
%define DEED_RESTORED  8
%define DEED_SLAIN     9
%define DEED_STOLEN    10
%define DEED_PLEDGED   11
%define DEED_DEFECTED  12
%define DEED_KINDS     13

; deeds table entry: name (40) + 13 qword counters
%define DEED_ENTRY_NAME   0
%define DEED_ENTRY_COUNTS 40
%define DEED_ENTRY_SIZE   144
%define DEED_MAX_ENTRIES  64

; saved-souls table entry: player name (40) + count (8) + 6 saved names x 24
%define SAVED_ENTRY_NAME  0
%define SAVED_ENTRY_COUNT 40
%define SAVED_ENTRY_LIST  48
%define SAVED_NAME_SIZE   24
%define SAVED_MAX_NAMES   6
%define SAVED_ENTRY_SIZE  192
%define SAVED_MAX_ENTRIES 64

; pair tables (forgiven / kept): two 40-byte names per row
%define PAIR_A 0
%define PAIR_B 40
%define PAIR_SIZE 80
%define PAIR_MAX 128

%define CAGE_REFILL_MS 240000
%define WARDEN_GRACE_MS 180000
%define STRAY_FLOOR -20
%define REDEEM_CEIL 5

%endif
