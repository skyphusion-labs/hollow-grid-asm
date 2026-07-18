%ifndef HG_STATE_INC
%define HG_STATE_INC

%define HG_EVT_CONNECTED 1
%define HG_EVT_RECEIVE   2
%define HG_EVT_WRITABLE  3
%define HG_EVT_CLOSED    4

%define HG_LOGIN_NAME 0
%define HG_LOGIN_RACE 1
%define HG_LOGIN_PLAY 2

%define SESSION_STATE    0
%define SESSION_NAME     8
%define SESSION_RACE     48
%define SESSION_ROOM     64
%define SESSION_HP       72
%define SESSION_MAX_HP   80
%define SESSION_LEVEL    88
%define SESSION_XP       96
%define SESSION_GOLD     104
%define SESSION_OUT_LEN  112
%define SESSION_CLOSE    120
%define SESSION_OUT      128
%define SESSION_OUT_CAP  8192
%define SESSION_SIZE     8320

%define ROOM_NEXUS   0
%define ROOM_TUNNELS 1

%endif
