/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | modules/display/
 *
 * 职责: LCD — 7页菜单 + 6子界面
 * 参照: ridewind-esp ui_manager（enter/update模式）
 *
 * 刷新: 事件驱动 — 只在编码器事件时重绘，无定时器刷新
 * ═══════════════════════════════════════════════════════════════ */

#include "display_module.h"
#include "core/hal/hal_lcd.h"
#include "core/state/app_state.h"
#include "esp_log.h"
#include <string.h>
#include <stdio.h>
#include <math.h>

static const char *TAG = "DISP";

#define C_BLACK   0x0000
#define C_WHITE   0xFFFF
#define C_GRAY    0x8410
#define C_DARK    0x2104
#define C_GREEN   0x07E0
#define C_CYAN    0x07FF
#define C_BLUE    0x001F
#define C_RED     0xF800
#define C_ORANGE  0xFC00
#define C_TEAL    0x0410

#define LCD_W  240
#define LCD_H  240
#define LCD_CX 120
#define LCD_CY 120

static const uint8_t PN[][8] = {
    "","RAINBOW","BREATH","FLOW","RIPPLE","PULSE","FIRE","OCEAN",
    "FOREST","SUNSET","AURORA","NEON","MARS","DEW","MOON"
};
static const char *MN[] = {"SPEED","COLOR","RGB","BRIGHT","LOGO","VOLUME","VOICE"};

static uint8_t s_page = 0xFF;       /* 当前页面，用于 enter 检测 */
static uint8_t s_menu_cur = 0;      /* 菜单光标 */

/* ═══════════════════════════════════════════════════════════════ */
void display_module_init(void)
{
    hal_lcd_clear(C_BLACK);
    hal_lcd_fill_rect(0,0,80,6,C_GREEN);
    hal_lcd_fill_rect(80,0,80,6,C_CYAN);
    hal_lcd_fill_rect(160,0,80,6,C_BLUE);
    hal_lcd_draw_string(40,40,"ZCRITICAL",C_WHITE,C_BLACK,2);
    hal_lcd_draw_string(82,80,"T1",C_CYAN,C_BLACK,2);
    hal_lcd_draw_string(76,130,"v1.0.0",C_GRAY,C_BLACK,1);
    hal_lcd_draw_string(42,170,"BLE:T1",C_GREEN,C_BLACK,1);
    hal_lcd_draw_string(42,190,"LCD:OK",C_GREEN,C_BLACK,1);
    ESP_LOGI(TAG,"Splash");
}

void display_module_lcd_on(uint8_t on) {
    hal_lcd_set_backlight(on!=0);
    APP_STATE_LOCK(); g_app_state.ui.lcd_on=on; APP_STATE_UNLOCK();
}

/* ═══════════════════════════════════════════════════════════════
 *  页面切换（对标 ui_manager 的 enter 检测）
 * ═══════════════════════════════════════════════════════════════ */
void display_module_switch(uint8_t page)
{
    APP_STATE_LOCK(); g_app_state.ui.page=page; APP_STATE_UNLOCK();
    s_page = 0xFF;  /* 强制 enter */
    display_module_render();
}

/* ═══════════════════════════════════════════════════════════════
 *  Menu
 * ═══════════════════════════════════════════════════════════════ */
static void draw_menu(void)
{
    hal_lcd_clear(C_BLACK);
    hal_lcd_fill_rect(0,0,LCD_W,22,C_DARK);
    hal_lcd_draw_string(6,3,"MENU",C_WHITE,C_DARK,1);

    for (int i=0;i<7;i++){
        int y=35+i*30;
        uint16_t bg=(i==s_menu_cur)?C_TEAL:C_DARK;
        hal_lcd_fill_rect(20,y,LCD_W-40,26,bg);
        hal_lcd_draw_string(30,y+4,MN[i],C_WHITE,bg,1);
    }
    hal_lcd_fill_rect(0,LCD_H-16,LCD_W,16,C_DARK);
    hal_lcd_draw_string(8,LCD_H-14,"<>SEL  1=ENTER  2=BACK",C_GRAY,C_DARK,1);

    APP_STATE_LOCK(); g_app_state.ui.menu_selected=s_menu_cur; APP_STATE_UNLOCK();
}

void display_menu_navigate(int8_t dir)
{
    int8_t n=(int8_t)s_menu_cur+dir;
    if (n<0)n=PAGE_COUNT-1;
    if (n>=PAGE_COUNT)n=0;
    s_menu_cur=(uint8_t)n;
    draw_menu();
}

void display_menu_select(void)
{
    static const uint8_t M[]={PAGE_SPEED,PAGE_COLOR,PAGE_RGB,PAGE_BRIGHT,PAGE_LOGO,PAGE_VOLUME,PAGE_SPEED};
    ESP_LOGI(TAG,"→ page %d",M[s_menu_cur]);
    display_module_switch(M[s_menu_cur]);
}

/* ═══════════════════════════════════════════════════════════════
 *  Speed（对标 ui_speed）
 * ═══════════════════════════════════════════════════════════════ */
static void draw_speed(void)
{
    hal_lcd_clear(C_BLACK);
    hal_lcd_fill_rect(0,0,LCD_W,22,C_DARK);
    hal_lcd_draw_string(6,3,"SPEED",C_WHITE,C_DARK,1);

    uint8_t spd=0,unit=0,wh=0;
    APP_STATE_LOCK();
    spd=g_app_state.fan.speed; unit=g_app_state.fan.unit;
    wh=g_app_state.fan.wuhuaqi;
    APP_STATE_UNLOCK();

    /* 刻度环 */
    for (int i=0;i<24;i++){
        float a=(float)i*15.0f*3.14159265f/180.0f;
        uint16_t x1=(uint16_t)(LCD_CX+(119-19)*sinf(a));
        uint16_t y1=(uint16_t)(LCD_CY-(119-19)*cosf(a));
        uint16_t x2,y2;
        if (i%2==0){
            x2=(uint16_t)(LCD_CX+(119-9)*sinf(a));
            y2=(uint16_t)(LCD_CY-(119-9)*cosf(a));
            hal_lcd_draw_line(x1,y1,x2,y2,C_WHITE);
        }else{
            x2=(uint16_t)(LCD_CX+(119-13)*sinf(a));
            y2=(uint16_t)(LCD_CY-(119-13)*cosf(a));
            hal_lcd_draw_line(x1,y1,x2,y2,C_GRAY);
        }
    }

    char b[16]; snprintf(b,sizeof(b),"%d",spd);
    hal_lcd_draw_string((uint16_t)(LCD_CX-(strlen(b)*8)/2),LCD_CY-5,b,C_WHITE,C_BLACK,3);

    const char *u=unit?"mph":"km/h";
    hal_lcd_draw_string((uint16_t)(LCD_CX-(strlen(u)*6)/2),LCD_CY+22,u,C_GRAY,C_BLACK,1);

    const char *st="NORMAL";
    if (wh==2)st="THROTTLE"; else if (wh==1)st="HUM ON";
    hal_lcd_draw_string((uint16_t)(LCD_CX-(strlen(st)*6)/2),LCD_CY-42,st,
        (wh==2)?C_ORANGE:((wh==1)?C_CYAN:C_GRAY),C_BLACK,1);

    hal_lcd_fill_rect(0,LCD_H-16,LCD_W,16,C_DARK);
    hal_lcd_draw_string(8,LCD_H-14,"<>SPD  1=UNIT  2=BACK",C_GRAY,C_DARK,1);
}

/* ═══════════════════════════════════════════════════════════════
 *  Color（对标 ui_preset）
 * ═══════════════════════════════════════════════════════════════ */
static void draw_color(void)
{
    hal_lcd_clear(C_BLACK);
    hal_lcd_fill_rect(0,0,LCD_W,22,C_DARK);
    hal_lcd_draw_string(6,3,"COLOR PRESET",C_WHITE,C_DARK,1);

    uint8_t pr=0;
    APP_STATE_LOCK(); pr=g_app_state.led.preset; APP_STATE_UNLOCK();

    for (int i=1;i<=14;i++){
        int col=(i-1)/7,row=(i-1)%7;
        int x=15+col*110,y=32+row*27;
        uint16_t bg=(i==pr)?C_TEAL:C_DARK;
        hal_lcd_fill_rect(x,y,95,22,bg);
        hal_lcd_draw_string(x+4,y+4,(const char*)PN[i],(i==pr)?C_WHITE:C_GRAY,C_DARK,1);
    }
    hal_lcd_fill_rect(0,LCD_H-16,LCD_W,16,C_DARK);
    hal_lcd_draw_string(8,LCD_H-14,"<>PRESET  2=BACK",C_GRAY,C_DARK,1);
}

/* ═══════════════════════════════════════════════════════════════
 *  RGB
 * ═══════════════════════════════════════════════════════════════ */
static void draw_rgb(void)
{
    hal_lcd_clear(C_BLACK);
    hal_lcd_fill_rect(0,0,LCD_W,22,C_DARK);
    hal_lcd_draw_string(6,3,"RGB EDIT",C_WHITE,C_DARK,1);

    uint8_t r=0,g=0,b=0;
    APP_STATE_LOCK();
    r=g_app_state.led.colors[0][0]; g=g_app_state.led.colors[0][1];
    b=g_app_state.led.colors[0][2];
    APP_STATE_UNLOCK();

    uint16_t pc=((uint16_t)(r>>3)<<11)|((uint16_t)(g>>2)<<5)|(b>>3);
    hal_lcd_draw_circle(LCD_CX,55,35,pc,true);

    uint16_t vals[]={r,g,b};
    const char *chs[]={"R","G","B"};
    for (int i=0;i<3;i++){
        int y=110+i*32;
        uint16_t bg=(i==0)?C_DARK:C_DARK;
        hal_lcd_fill_rect(20,y,200,24,bg);
        char lb[32]; snprintf(lb,sizeof(lb),"%s:%d",chs[i],(int)vals[i]);
        hal_lcd_draw_string(28,y+4,lb,C_WHITE,C_DARK,1);
        uint16_t bc=(i==0)?C_RED:((i==1)?C_GREEN:C_BLUE);
        hal_lcd_fill_rect(80,y+20,(uint16_t)(vals[i]*120/255),3,bc);
    }
    hal_lcd_fill_rect(0,LCD_H-16,LCD_W,16,C_DARK);
    hal_lcd_draw_string(8,LCD_H-14,"<>CH  1=ADJ  2=BACK",C_GRAY,C_DARK,1);
}

/* ═══════════════════════════════════════════════════════════════
 *  Bright（对标 ui_bright）
 * ═══════════════════════════════════════════════════════════════ */
static void draw_bright(void)
{
    hal_lcd_clear(C_BLACK);
    hal_lcd_fill_rect(0,0,LCD_W,22,C_DARK);
    hal_lcd_draw_string(6,3,"BRIGHT",C_WHITE,C_DARK,1);

    uint8_t br=0;
    APP_STATE_LOCK(); br=g_app_state.led.brightness; APP_STATE_UNLOCK();

    char b[8]; snprintf(b,sizeof(b),"%d%%",br);
    hal_lcd_draw_string((uint16_t)(LCD_CX-14),70,b,C_WHITE,C_BLACK,2);
    hal_lcd_fill_rect(30,120,180,24,C_DARK);
    hal_lcd_fill_rect(30,120,(uint16_t)(br*180/100),24,C_CYAN);

    hal_lcd_fill_rect(0,LCD_H-16,LCD_W,16,C_DARK);
    hal_lcd_draw_string(8,LCD_H-14,"<>BR  2=BACK",C_GRAY,C_DARK,1);
}

/* ═══════════════════════════════════════════════════════════════
 *  Logo
 * ═══════════════════════════════════════════════════════════════ */
static void draw_logo(void)
{
    hal_lcd_clear(C_BLACK);
    hal_lcd_fill_rect(0,0,LCD_W,22,C_DARK);
    hal_lcd_draw_string(6,3,"LOGO",C_WHITE,C_DARK,1);
    hal_lcd_draw_string(60,80,"LOGO MGR",C_WHITE,C_BLACK,2);

    uint8_t s[4];
    APP_STATE_LOCK();
    s[0]=g_app_state.logo.slots[0]; s[1]=g_app_state.logo.slots[1];
    s[2]=g_app_state.logo.slots[2]; s[3]=g_app_state.logo.active_slot;
    APP_STATE_UNLOCK();

    for (int i=0;i<4;i++){
        char t[8]; snprintf(t,sizeof(t),"%d:%s",i+1,s[i]?"OK":"--");
        hal_lcd_draw_string(70,155+i*16,t,s[i]?C_GREEN:C_GRAY,C_BLACK,1);
    }
    hal_lcd_fill_rect(0,LCD_H-16,LCD_W,16,C_DARK);
    hal_lcd_draw_string(8,LCD_H-14,"2=BACK",C_GRAY,C_DARK,1);
}

/* ═══════════════════════════════════════════════════════════════
 *  Volume
 * ═══════════════════════════════════════════════════════════════ */
static void draw_volume(void)
{
    hal_lcd_clear(C_BLACK);
    hal_lcd_fill_rect(0,0,LCD_W,22,C_DARK);
    hal_lcd_draw_string(6,3,"VOLUME",C_WHITE,C_DARK,1);

    uint8_t vol=0;
    APP_STATE_LOCK(); vol=g_app_state.audio.volume; APP_STATE_UNLOCK();

    char b[8]; snprintf(b,sizeof(b),"%d%%",vol);
    hal_lcd_draw_string((uint16_t)(LCD_CX-14),70,b,C_WHITE,C_BLACK,2);
    hal_lcd_fill_rect(30,120,180,24,C_DARK);
    hal_lcd_fill_rect(30,120,(uint16_t)(vol*180/100),24,C_GREEN);

    hal_lcd_fill_rect(0,LCD_H-16,LCD_W,16,C_DARK);
    hal_lcd_draw_string(8,LCD_H-14,"<>VOL  2=BACK",C_GRAY,C_DARK,1);
}

/* ═══════════════════════════════════════════════════════════════
 *  渲染调度（对标 ui_manager_update）
 * ═══════════════════════════════════════════════════════════════ */
void display_module_render(void)
{
    uint8_t pg;
    APP_STATE_LOCK(); pg=g_app_state.ui.page; APP_STATE_UNLOCK();

    if (pg==s_page) return;  /* 无变化，不重绘 */
    s_page=pg;

    switch (pg) {
    case PAGE_MENU:   draw_menu();    break;
    case PAGE_SPEED:  draw_speed();   break;
    case PAGE_COLOR:  draw_color();   break;
    case PAGE_RGB:    draw_rgb();     break;
    case PAGE_BRIGHT: draw_bright();  break;
    case PAGE_LOGO:   draw_logo();    break;
    case PAGE_VOLUME: draw_volume();  break;
    default: break;
    }
}

/* ── 向后兼容的桩函数 ── */
void display_speed_enter(void)  { s_page=0xFF; display_module_switch(PAGE_SPEED); }
void display_color_enter(void)  { s_page=0xFF; display_module_switch(PAGE_COLOR); }
void display_rgb_enter(void)    { s_page=0xFF; display_module_switch(PAGE_RGB); }
void display_bright_enter(void) { s_page=0xFF; display_module_switch(PAGE_BRIGHT); }
void display_logo_enter(void)   { s_page=0xFF; display_module_switch(PAGE_LOGO); }
void display_volume_enter(void) { s_page=0xFF; display_module_switch(PAGE_VOLUME); }
void display_speed_update(void)   { draw_speed(); }
void display_color_update(void)   { draw_color(); }
void display_rgb_update(void)     { draw_rgb(); }
void display_bright_update(void)  { draw_bright(); }
void display_logo_update(void)    {}
void display_volume_update(void)  { draw_volume(); }
void display_rgb_rotate(int d)    { (void)d; draw_rgb(); }
