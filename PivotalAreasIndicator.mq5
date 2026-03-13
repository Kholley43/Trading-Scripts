#property strict
#property indicator_chart_window
#property indicator_plots 1
#property indicator_buffers 1
#property indicator_type1 DRAW_NONE
#property indicator_label1 "PivotalAreas"

#include <PivotalAreasCore.mqh>

input ENUM_TIMEFRAMES InpSignalTimeframe         = PERIOD_M15;
input ENUM_TIMEFRAMES InpStructureTimeframe      = PERIOD_H1;
input int             InpSignalBars              = 160;
input int             InpStructureLookback       = 300;
input int             InpSwingStrength           = 2;
input int             InpATRPeriod               = 14;
input double          InpZoneWidthAtrMultiplier  = 0.30;
input double          InpTouchTolerancePoints    = 35.0;
input int             InpMinConfluenceScore      = 10;
input double          InpRejectionCloseRatio     = 0.65;
input double          InpBreakoutBodyRatio       = 0.60;
input int             InpRetestTimeoutBars       = 3;
input double          InpMinBarrierRoomRisk      = 1.25;
input bool            InpShowDailyPivots         = false;
input bool            InpShowWeeklyPivots        = true;
input bool            InpShowDailyOpen           = true;
input bool            InpShowWeeklyOpen          = true;
input bool            InpShowDailyHighLow        = true;
input bool            InpShowWeeklyHighLow       = true;
input bool            InpShowDailyVWAP           = true;
input bool            InpShowWeeklyVWAP          = true;
input bool            InpShowSupplyDemand        = true;
input bool            InpShowSupportResistance   = false;
input bool            InpShowSignalText          = true;
input string          InpObjectPrefix            = "PA_IND_";

double g_buffer[];
datetime g_last_chart_bar_time = 0;

color PA_LevelColor(const PA_Level &level)
  {
   switch(level.kind)
     {
      case PA_LEVEL_WEEKLY_PIVOT:
      case PA_LEVEL_WEEKLY_R1:
      case PA_LEVEL_WEEKLY_S1:
      case PA_LEVEL_WEEKLY_R2:
      case PA_LEVEL_WEEKLY_S2:
      case PA_LEVEL_WEEKLY_OPEN:
      case PA_LEVEL_WEEKLY_HIGH:
      case PA_LEVEL_WEEKLY_LOW:
      case PA_LEVEL_WEEKLY_VWAP:
         return(clrDeepSkyBlue);

      case PA_LEVEL_DAILY_PIVOT:
      case PA_LEVEL_DAILY_R1:
      case PA_LEVEL_DAILY_S1:
      case PA_LEVEL_DAILY_R2:
      case PA_LEVEL_DAILY_S2:
      case PA_LEVEL_DAILY_OPEN:
      case PA_LEVEL_DAILY_HIGH:
      case PA_LEVEL_DAILY_LOW:
      case PA_LEVEL_DAILY_VWAP:
         return(clrGold);

      case PA_LEVEL_SUPPLY_ZONE:
      case PA_LEVEL_RESISTANCE:
         return(clrTomato);

      case PA_LEVEL_DEMAND_ZONE:
      case PA_LEVEL_SUPPORT:
         return(clrLimeGreen);
     }
   return(clrSilver);
  }

int PA_LevelWidth(const PA_Level &level)
  {
   if(level.weight >= 6)
      return(2);
   return(1);
  }

void PA_ClearObjects(const string prefix)
  {
   for(int i = ObjectsTotal(0,-1,-1) - 1; i >= 0; --i)
     {
      const string name = ObjectName(0,i);
      if(StringFind(name,prefix) == 0)
         ObjectDelete(0,name);
     }
  }

void PA_DrawLineLevel(const string prefix,const PA_Level &level,const datetime label_time)
  {
   const string line_name = prefix + level.id;
   ObjectCreate(0,line_name,OBJ_HLINE,0,0,level.price);
   ObjectSetInteger(0,line_name,OBJPROP_COLOR,PA_LevelColor(level));
   ObjectSetInteger(0,line_name,OBJPROP_STYLE,level.weight >= 5 ? STYLE_SOLID : STYLE_DOT);
   ObjectSetInteger(0,line_name,OBJPROP_WIDTH,PA_LevelWidth(level));
   ObjectSetInteger(0,line_name,OBJPROP_BACK,true);

   const string text_name = line_name + "_label";
   ObjectCreate(0,text_name,OBJ_TEXT,0,label_time,level.price);
   ObjectSetString(0,text_name,OBJPROP_TEXT,level.label);
   ObjectSetInteger(0,text_name,OBJPROP_COLOR,PA_LevelColor(level));
   ObjectSetInteger(0,text_name,OBJPROP_ANCHOR,ANCHOR_LEFT);
   ObjectSetInteger(0,text_name,OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,text_name,OBJPROP_BACK,false);
  }

void PA_DrawZoneLevel(const string prefix,const PA_Level &level,const datetime start_time,const datetime end_time)
  {
   const string rect_name = prefix + level.id;
   ObjectCreate(0,rect_name,OBJ_RECTANGLE,0,start_time,level.upper_bound,end_time,level.lower_bound);
   ObjectSetInteger(0,rect_name,OBJPROP_COLOR,PA_LevelColor(level));
   ObjectSetInteger(0,rect_name,OBJPROP_FILL,true);
   ObjectSetInteger(0,rect_name,OBJPROP_BACK,true);
   ObjectSetInteger(0,rect_name,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSetInteger(0,rect_name,OBJPROP_WIDTH,1);
   ObjectSetInteger(0,rect_name,OBJPROP_COLOR,ColorToARGB(PA_LevelColor(level),55));

   const string text_name = rect_name + "_label";
   ObjectCreate(0,text_name,OBJ_TEXT,0,end_time,level.price);
   ObjectSetString(0,text_name,OBJPROP_TEXT,level.label);
   ObjectSetInteger(0,text_name,OBJPROP_COLOR,PA_LevelColor(level));
   ObjectSetInteger(0,text_name,OBJPROP_ANCHOR,ANCHOR_LEFT);
   ObjectSetInteger(0,text_name,OBJPROP_FONTSIZE,8);
  }

void PA_DrawSignal(const string prefix,const PA_Signal &signal)
  {
   if(signal.kind == PA_SIGNAL_NONE)
      return;

   const color signal_color = (signal.direction > 0 ? clrLime : clrTomato);
   const int arrow_code = (signal.direction > 0 ? 233 : 234);
   const string suffix = IntegerToString((int)signal.signal_time);

   const string arrow_name = prefix + "signal_arrow_" + suffix;
   ObjectCreate(0,arrow_name,OBJ_ARROW,0,signal.signal_time,signal.entry_price);
   ObjectSetInteger(0,arrow_name,OBJPROP_ARROWCODE,arrow_code);
   ObjectSetInteger(0,arrow_name,OBJPROP_COLOR,signal_color);
   ObjectSetInteger(0,arrow_name,OBJPROP_WIDTH,2);

   if(!InpShowSignalText)
      return;

   const string text_name = prefix + "signal_text_" + suffix;
   ObjectCreate(0,text_name,OBJ_TEXT,0,signal.signal_time,signal.entry_price);
   ObjectSetString(0,text_name,OBJPROP_TEXT,StringFormat("%s | score=%d",PA_SignalKindLabel(signal.kind),signal.confluence_score));
   ObjectSetInteger(0,text_name,OBJPROP_COLOR,signal_color);
   ObjectSetInteger(0,text_name,OBJPROP_ANCHOR,(signal.direction > 0 ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER));
   ObjectSetInteger(0,text_name,OBJPROP_FONTSIZE,9);
  }

void PA_LoadIndicatorFilters(PA_LevelFilters &filters)
  {
   PA_DefaultFilters(filters);
   filters.use_daily_pivots       = InpShowDailyPivots;
   filters.use_weekly_pivots      = InpShowWeeklyPivots;
   filters.use_daily_open         = InpShowDailyOpen;
   filters.use_weekly_open        = InpShowWeeklyOpen;
   filters.use_daily_high_low     = InpShowDailyHighLow;
   filters.use_weekly_high_low    = InpShowWeeklyHighLow;
   filters.use_daily_vwap         = InpShowDailyVWAP;
   filters.use_weekly_vwap        = InpShowWeeklyVWAP;
   filters.use_supply_demand      = InpShowSupplyDemand;
   filters.use_support_resistance = InpShowSupportResistance;
  }

int OnInit()
  {
   SetIndexBuffer(0,g_buffer,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);
   IndicatorSetString(INDICATOR_SHORTNAME,"Pivotal Areas");
   ArrayInitialize(g_buffer,EMPTY_VALUE);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   PA_ClearObjects(InpObjectPrefix);
   Comment("");
  }

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
   if(rates_total < 10)
      return(rates_total);

   if(time[0] == g_last_chart_bar_time && prev_calculated > 0)
      return(rates_total);

   g_last_chart_bar_time = time[0];

   PA_LevelFilters filters;
   PA_LoadIndicatorFilters(filters);

   PA_Context context;
   if(!PA_BuildContext(_Symbol,
                       InpSignalTimeframe,
                       InpStructureTimeframe,
                       InpSignalBars,
                       InpStructureLookback,
                       InpSwingStrength,
                       InpATRPeriod,
                       InpZoneWidthAtrMultiplier,
                       filters,
                       context))
      return(rates_total);

   PA_Signal signal;
   PA_EvaluateSignal(context,
                     InpTouchTolerancePoints,
                     InpMinConfluenceScore,
                     InpRejectionCloseRatio,
                     InpBreakoutBodyRatio,
                     InpRetestTimeoutBars,
                     InpMinBarrierRoomRisk,
                     signal);

   PA_ClearObjects(InpObjectPrefix);

   const datetime chart_start = time[MathMax(rates_total - 1,0)];
   const datetime chart_end   = time[0] + (datetime)(PeriodSeconds(PERIOD_CURRENT) * 12);
   const datetime label_time  = time[0] + (datetime)(PeriodSeconds(PERIOD_CURRENT) * 3);

   for(int i = 0; i < ArraySize(context.levels); ++i)
     {
      if(context.levels[i].is_zone)
         PA_DrawZoneLevel(InpObjectPrefix,context.levels[i],chart_start,chart_end);
      else
         PA_DrawLineLevel(InpObjectPrefix,context.levels[i],label_time);
     }

   PA_DrawSignal(InpObjectPrefix,signal);

   if(signal.kind == PA_SIGNAL_NONE)
      Comment("Pivotal Areas H1->M15: waiting for clean rejection or break-retest at stacked levels");
   else
      Comment(StringFormat("Pivotal Areas H1->M15 | %s | score=%d | levels=%s",
                           PA_SignalKindLabel(signal.kind),
                           signal.confluence_score,
                           signal.matched_levels));

   return(rates_total);
  }
