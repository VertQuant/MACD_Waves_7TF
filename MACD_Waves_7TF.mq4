#property copyright   "VertQuant, 2026"
#property link        "https://www.youtube.com/@VertQuant"
#property description "MACD 12/26/9 on D1, H4, H1, M30, M15, M5, M1 drawn as seven waves."
#property description "Closed candles only. Colour = strict momentum: MACD > 0, above its EMA signal line and rising."
#property description "Gold dot = CONFLICT: D1 and H4 agree, M15/M5/M1 all point the other way."
#property version     "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 23
#property indicator_minimum -0.6
#property indicator_maximum 7.6

input int    InpFast        = 12;
input int    InpSlow        = 26;
input int    InpSignal      = 9;
input int    InpBarsToDraw  = 3000;
input int    InpHistoryTF   = 3000;
input int    InpWarmup      = 300;
input int    InpResyncMin   = 240;
input bool   InpExportCSV   = false;
input color  InpColUp       = C'0,212,198';
input color  InpColDn       = C'255,179,71';
input color  InpColFlat     = C'85,88,100';
input int    InpWidthColor  = 4;
input int    InpWidthFlat   = 2;
input color  InpColConflict = C'255,215,0';

#define NTF 7
int    g_tf[NTF]   = {PERIOD_D1, PERIOD_H4, PERIOD_H1, PERIOD_M30, PERIOD_M15, PERIOD_M5, PERIOD_M1};
string g_name[NTF] = {"D1", "H4", "H1", "M30", "M15", "M5", "M1"};
string g_prefix    = "VQ_MW7_";
string g_short     = "VQ MACD Waves 7TF";
int    g_cur_s[NTF];

double U0[],D0[],N0[],U1[],D1[],N1[],U2[],D2[],N2[],U3[],D3[],N3[];
double U4[],D4[],N4[],U5[],D5[],N5[],U6[],D6[],N6[];
double ConflictMark[], ResyncMark[];

class CTimeframe
  {
public:
   int               tf;
   int               n;
   datetime          last_open;
   double            m[];
   double            h[];
   double            scale;

   void              Init(int timeframe) { tf = timeframe; n = 0; last_open = 0; scale = 0; }

   bool              Update()
     {
      int bars = iBars(_Symbol, tf);
      if(bars < InpWarmup + InpSlow + InpSignal + 2)
         return(false);
      datetime t0 = iTime(_Symbol, tf, 0);
      if(t0 == last_open && n > 0)
         return(true);
      last_open = t0;
      n = MathMin(bars, InpHistoryTF);
      ArrayResize(m, n);
      ArrayResize(h, n);
      double af = 2.0 / (InpFast + 1), as = 2.0 / (InpSlow + 1), ag = 2.0 / (InpSignal + 1);
      double ef = 0, es = 0, sg = 0;
      for(int j = n - 1; j >= 0; j--)
        {
         double c = iClose(_Symbol, tf, j);
         if(j == n - 1)
           { ef = c; es = c; }
         else
           { ef += af * (c - ef); es += as * (c - es); }
         double mm = ef - es;
         if(j == n - 1)
            sg = mm;
         else
            sg += ag * (mm - sg);
         m[j] = mm;
         h[j] = mm - sg;
        }
      double s = 0, s2 = 0;
      int cnt = 0;
      for(int j = 1; j < n - InpWarmup; j++)
        { s += h[j]; s2 += h[j] * h[j]; cnt++; }
      scale = (cnt > 1) ? MathSqrt(MathMax(s2 / cnt - (s / cnt) * (s / cnt), 0)) : 0;
      return(true);
     }

   int               LastClosed(datetime t_dec)
     {
      int s = iBarShift(_Symbol, tf, t_dec - 1, false);
      if(s < 0)
         return(-1);
      if(iTime(_Symbol, tf, s) + PeriodSeconds(tf) > t_dec)
         s++;
      return(s);
     }

   bool              Usable(int s) { return(s >= 0 && s + 1 < n && s <= n - 1 - InpWarmup); }

   int               State(int s)
     {
      if(!Usable(s))
         return(0);
      double dm = m[s] - m[s + 1];
      if(dm > 0 && h[s] > 0 && m[s] > 0)
         return(1);
      if(dm < 0 && h[s] < 0 && m[s] < 0)
         return(-1);
      return(0);
     }
  };

CTimeframe g_t[NTF];

void SetWave(int k, int i, int which, double v)
  {
   int b = k * 3 + which;
   switch(b)
     {
      case 0: U0[i] = v; break;  case 1: D0[i] = v; break;  case 2: N0[i] = v; break;
      case 3: U1[i] = v; break;  case 4: D1[i] = v; break;  case 5: N1[i] = v; break;
      case 6: U2[i] = v; break;  case 7: D2[i] = v; break;  case 8: N2[i] = v; break;
      case 9: U3[i] = v; break;  case 10: D3[i] = v; break; case 11: N3[i] = v; break;
      case 12: U4[i] = v; break; case 13: D4[i] = v; break; case 14: N4[i] = v; break;
      case 15: U5[i] = v; break; case 16: D5[i] = v; break; case 17: N5[i] = v; break;
      case 18: U6[i] = v; break; case 19: D6[i] = v; break; case 20: N6[i] = v; break;
     }
  }

void BindWave(int b, double &buf[], string label, color clr, int width)
  {
   SetIndexBuffer(b, buf);
   SetIndexStyle(b, DRAW_LINE, STYLE_SOLID, width, clr);
   SetIndexLabel(b, NULL);
   SetIndexEmptyValue(b, EMPTY_VALUE);
   ArrayInitialize(buf, EMPTY_VALUE);
  }

int OnInit()
  {
   IndicatorShortName(g_short);
   IndicatorDigits(2);
   BindWave(0, U0, "D1 up", InpColUp, InpWidthColor);    BindWave(1, D0, "D1 down", InpColDn, InpWidthColor);    BindWave(2, N0, "D1", InpColFlat, InpWidthFlat);
   BindWave(3, U1, "H4 up", InpColUp, InpWidthColor);    BindWave(4, D1, "H4 down", InpColDn, InpWidthColor);    BindWave(5, N1, "H4", InpColFlat, InpWidthFlat);
   BindWave(6, U2, "H1 up", InpColUp, InpWidthColor);    BindWave(7, D2, "H1 down", InpColDn, InpWidthColor);    BindWave(8, N2, "H1", InpColFlat, InpWidthFlat);
   BindWave(9, U3, "M30 up", InpColUp, InpWidthColor);   BindWave(10, D3, "M30 down", InpColDn, InpWidthColor);  BindWave(11, N3, "M30", InpColFlat, InpWidthFlat);
   BindWave(12, U4, "M15 up", InpColUp, InpWidthColor);  BindWave(13, D4, "M15 down", InpColDn, InpWidthColor);  BindWave(14, N4, "M15", InpColFlat, InpWidthFlat);
   BindWave(15, U5, "M5 up", InpColUp, InpWidthColor);   BindWave(16, D5, "M5 down", InpColDn, InpWidthColor);   BindWave(17, N5, "M5", InpColFlat, InpWidthFlat);
   BindWave(18, U6, "M1 up", InpColUp, InpWidthColor);   BindWave(19, D6, "M1 down", InpColDn, InpWidthColor);   BindWave(20, N6, "M1", InpColFlat, InpWidthFlat);

   SetIndexBuffer(21, ConflictMark);
   SetIndexStyle(21, DRAW_ARROW, STYLE_SOLID, 2, InpColConflict);
   SetIndexArrow(21, 108);
   SetIndexLabel(21, NULL);
   SetIndexEmptyValue(21, EMPTY_VALUE);
   SetIndexBuffer(22, ResyncMark);
   SetIndexStyle(22, DRAW_ARROW, STYLE_SOLID, 1, InpColUp);
   SetIndexArrow(22, 167);
   SetIndexLabel(22, NULL);
   SetIndexEmptyValue(22, EMPTY_VALUE);

   for(int k = 0; k < NTF; k++)
      g_t[k].Init(g_tf[k]);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, g_prefix);
  }

datetime DecisionTime(const datetime &time[], int i)
  {
   if(i == 0)
      return(TimeCurrent());
   return(time[i] + PeriodSeconds());
  }

void RowName(int k, datetime t, double y)
  {
   string id = g_prefix + "row" + g_name[k];
   int win = WindowFind(g_short);
   if(win < 0)
      return;
   if(ObjectFind(0, id) < 0)
     {
      ObjectCreate(0, id, OBJ_TEXT, win, t, y);
      ObjectSetString(0, id, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(0, id, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, id, OBJPROP_ANCHOR, ANCHOR_LEFT);
      ObjectSetInteger(0, id, OBJPROP_SELECTABLE, false);
     }
   ObjectMove(0, id, 0, t, y);
   int s = g_cur_s[k];
   string txt = g_name[k];
   color clr = clrSilver;
   if(g_t[k].Usable(s))
     {
      int st = g_t[k].State(s);
      txt = StringFormat("%-4s %-5s %s", g_name[k], StateText(st), Signed(g_t[k].h[s]));
      clr = (st > 0) ? InpColUp : ((st < 0) ? InpColDn : InpColFlat);
      ObjectSetString(0, id, OBJPROP_TOOLTIP, StringFormat("%s  MACD %s  histogram %s", g_name[k],
                      Signed(g_t[k].m[s]), Signed(g_t[k].h[s])));
     }
   ObjectSetString(0, id, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, id, OBJPROP_COLOR, clr);
  }

string Signed(double v)
  {
   string t = DoubleToString(MathAbs(v), _Digits + 1);
   return((v >= 0 ? "+" : "-") + t);
  }

string StateText(int s) { return(s > 0 ? "up" : (s < 0 ? "down" : "flat")); }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   ArraySetAsSeries(time, true);
   for(int k = 0; k < NTF; k++)
      if(!g_t[k].Update())
         return(0);

   int last = MathMin(rates_total - 2, InpBarsToDraw);
   int prev_wave[NTF];
   int prevD = 0;
   bool prev_conflict = false, prev_with = false;
   datetime last_conflict = 0;
   int st[NTF];
   int D = 0;
   bool resync = false;

   int fh = INVALID_HANDLE;
   if(InpExportCSV && prev_calculated == 0)
     {
      fh = FileOpen("MACD_Waves_7TF_" + _Symbol + ".csv", FILE_WRITE | FILE_CSV | FILE_ANSI, ';');
      if(fh != INVALID_HANDLE)
         FileWrite(fh, "bar_time", "decision_time", "D1", "H4", "H1", "M30", "M15", "M5", "M1", "D", "conflict", "resync");
     }

   ArrayInitialize(prev_wave, -1);
   ArrayInitialize(st, 0);

   for(int i = last; i >= 0; i--)
     {
      datetime t_dec = DecisionTime(time, i);
      for(int k = 0; k < NTF; k++)
        {
         int s = g_t[k].LastClosed(t_dec);
         st[k] = g_t[k].State(s);
         if(i == 0)
            g_cur_s[k] = s;
         for(int w = 0; w < 3; w++)
            SetWave(k, i, w, EMPTY_VALUE);
         if(!g_t[k].Usable(s) || g_t[k].scale <= 0)
           { prev_wave[k] = -1; continue; }
         double v = g_t[k].h[s] / (3.0 * g_t[k].scale);
         v = MathMax(-1.0, MathMin(1.0, v));
         double y = (NTF - 1 - k) + 0.42 * v;
         int w = (st[k] > 0) ? 0 : ((st[k] < 0) ? 1 : 2);
         SetWave(k, i, w, y);
         if(prev_wave[k] >= 0 && prev_wave[k] != w && i + 1 < rates_total)
            SetWave(k, i, prev_wave[k], y);
         prev_wave[k] = w;
        }

      D = (st[0] == st[1] && st[0] != 0) ? st[0] : 0;
      bool lower_opp  = (D != 0 && st[4] == -D && st[5] == -D && st[6] == -D);
      bool lower_with = (D != 0 && st[4] == D && st[5] == D && st[6] == D);
      if(D != prevD)
         last_conflict = 0;
      if(lower_opp)
         last_conflict = t_dec;
      resync = lower_with && !prev_with && last_conflict > 0 && (t_dec - last_conflict) <= InpResyncMin * 60;

      ConflictMark[i] = (lower_opp && !prev_conflict) ? 7.3 : EMPTY_VALUE;
      ResyncMark[i]   = resync ? 7.3 : EMPTY_VALUE;
      prev_conflict = lower_opp;
      prev_with = lower_with;
      prevD = D;

      if(fh != INVALID_HANDLE)
         FileWrite(fh, TimeToString(time[i], TIME_DATE | TIME_MINUTES), TimeToString(t_dec, TIME_DATE | TIME_MINUTES),
                   st[0], st[1], st[2], st[3], st[4], st[5], st[6], D, (int)lower_opp, (int)resync);
     }
   if(fh != INVALID_HANDLE)
      FileClose(fh);

   datetime t_txt = time[0] + PeriodSeconds() * 2;
   for(int k = 0; k < NTF; k++)
      RowName(k, t_txt, NTF - 1 - k);

   return(rates_total);
  }
