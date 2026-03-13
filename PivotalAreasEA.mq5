#property strict

#include <Trade/Trade.mqh>
#include <PivotalAreasCore.mqh>

enum PA_POSITION_SIZE_MODEL
  {
   PA_SIZE_FIXED_LOT = 0,
   PA_SIZE_RISK_PERCENT
  };

enum PA_STOP_MODEL
  {
   PA_STOP_SIGNAL_LEVEL = 0,
   PA_STOP_ATR_BUFFER
  };

enum PA_TARGET_MODEL
  {
   PA_TARGET_RISK_REWARD = 0,
   PA_TARGET_NEXT_LEVEL
  };

input ENUM_TIMEFRAMES       InpSignalTimeframe         = PERIOD_M15;
input ENUM_TIMEFRAMES       InpStructureTimeframe      = PERIOD_H1;
input int                   InpSignalBars              = 160;
input int                   InpStructureLookback       = 300;
input int                   InpSwingStrength           = 2;
input int                   InpATRPeriod               = 14;
input double                InpZoneWidthAtrMultiplier  = 0.30;
input double                InpTouchTolerancePoints    = 35.0;
input int                   InpMinConfluenceScore      = 10;
input double                InpRejectionCloseRatio     = 0.65;
input double                InpBreakoutBodyRatio       = 0.60;
input int                   InpRetestTimeoutBars       = 3;
input double                InpMinBarrierRoomRisk      = 1.25;
input bool                  InpUseDailyPivots          = false;
input bool                  InpUseWeeklyPivots         = true;
input bool                  InpUseDailyOpen            = true;
input bool                  InpUseWeeklyOpen           = true;
input bool                  InpUseDailyHighLow         = true;
input bool                  InpUseWeeklyHighLow        = true;
input bool                  InpUseDailyVWAP            = true;
input bool                  InpUseWeeklyVWAP           = true;
input bool                  InpUseSupplyDemand         = true;
input bool                  InpUseSupportResistance    = false;
input PA_POSITION_SIZE_MODEL InpPositionSizing         = PA_SIZE_RISK_PERCENT;
input double                InpFixedLot               = 0.10;
input double                InpRiskPercent            = 0.50;
input PA_STOP_MODEL         InpStopModel              = PA_STOP_SIGNAL_LEVEL;
input double                InpStopAtrMultiplier      = 1.20;
input PA_TARGET_MODEL       InpTargetModel            = PA_TARGET_RISK_REWARD;
input double                InpRiskRewardRatio        = 2.00;
input int                   InpSessionStartHour       = 0;
input int                   InpSessionEndHour         = 23;
input int                   InpMaxTradesPerDay        = 1;
input bool                  InpBreakEvenEnabled       = true;
input double                InpBreakEvenRR            = 1.00;
input bool                  InpTrailingEnabled        = true;
input double                InpTrailingStopPoints     = 150.0;
input bool                  InpOnePositionPerSymbol   = true;
input long                  InpMagicNumber            = 260313;
input int                   InpSlippagePoints         = 20;
input bool                  InpDebugPrints            = true;

CTrade   g_trade;
datetime g_last_signal_bar = 0;
datetime g_last_trade_signal_time = 0;
int      g_trade_day_key = -1;
int      g_trade_count_today = 0;

int PA_DayKey(const datetime when)
  {
   MqlDateTime stamp;
   TimeToStruct(when,stamp);
   return(stamp.year * 10000 + stamp.mon * 100 + stamp.day);
  }

void PA_ResetDailyTradeCounter()
  {
   const int day_key = PA_DayKey(TimeCurrent());
   if(day_key != g_trade_day_key)
     {
      g_trade_day_key = day_key;
      g_trade_count_today = 0;
     }
  }

void PA_LoadEAFilters(PA_LevelFilters &filters)
  {
   PA_DefaultFilters(filters);
   filters.use_daily_pivots       = InpUseDailyPivots;
   filters.use_weekly_pivots      = InpUseWeeklyPivots;
   filters.use_daily_open         = InpUseDailyOpen;
   filters.use_weekly_open        = InpUseWeeklyOpen;
   filters.use_daily_high_low     = InpUseDailyHighLow;
   filters.use_weekly_high_low    = InpUseWeeklyHighLow;
   filters.use_daily_vwap         = InpUseDailyVWAP;
   filters.use_weekly_vwap        = InpUseWeeklyVWAP;
   filters.use_supply_demand      = InpUseSupplyDemand;
   filters.use_support_resistance = InpUseSupportResistance;
  }

bool PA_IsSessionOpen()
  {
   MqlDateTime stamp;
   TimeToStruct(TimeCurrent(),stamp);

   if(InpSessionStartHour == InpSessionEndHour)
      return(true);

   if(InpSessionStartHour < InpSessionEndHour)
      return(stamp.hour >= InpSessionStartHour && stamp.hour <= InpSessionEndHour);

   return(stamp.hour >= InpSessionStartHour || stamp.hour <= InpSessionEndHour);
  }

bool PA_GetManagedPosition(const string symbol,const long magic,ulong &ticket,long &type,double &open_price,double &stop_loss,double &take_profit,double &volume)
  {
   for(int i = PositionsTotal() - 1; i >= 0; --i)
     {
      const ulong candidate_ticket = PositionGetTicket(i);
      if(candidate_ticket == 0 || !PositionSelectByTicket(candidate_ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC) != magic)
         continue;

      ticket     = candidate_ticket;
      type       = PositionGetInteger(POSITION_TYPE);
      open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      stop_loss  = PositionGetDouble(POSITION_SL);
      take_profit= PositionGetDouble(POSITION_TP);
      volume     = PositionGetDouble(POSITION_VOLUME);
      return(true);
     }
   return(false);
  }

double PA_NormalizeVolume(const string symbol,const double raw_volume)
  {
   const double min_volume  = SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
   const double max_volume  = SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
   const double step_volume = SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);

   double volume = MathMax(min_volume,MathMin(max_volume,raw_volume));
   if(step_volume > 0.0)
      volume = MathFloor(volume / step_volume) * step_volume;
   return(NormalizeDouble(volume,2));
  }

double PA_CalcPositionSize(const string symbol,const double entry_price,const double stop_price)
  {
   if(InpPositionSizing == PA_SIZE_FIXED_LOT)
      return(PA_NormalizeVolume(symbol,InpFixedLot));

   const double balance    = AccountInfoDouble(ACCOUNT_BALANCE);
   const double risk_money = balance * (InpRiskPercent / 100.0);
   const double tick_size  = SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
   const double tick_value = SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE);
   const double distance   = MathAbs(entry_price - stop_price);

   if(risk_money <= 0.0 || tick_size <= 0.0 || tick_value <= 0.0 || distance <= 0.0)
      return(PA_NormalizeVolume(symbol,InpFixedLot));

   const double loss_per_lot = (distance / tick_size) * tick_value;
   if(loss_per_lot <= 0.0)
      return(PA_NormalizeVolume(symbol,InpFixedLot));

   return(PA_NormalizeVolume(symbol,risk_money / loss_per_lot));
  }

double PA_DetermineStop(const PA_Context &context,const PA_Signal &signal,const double entry_price)
  {
   if(InpStopModel == PA_STOP_SIGNAL_LEVEL)
      return(PA_NormalizePrice(context.symbol,signal.stop_price));

   const double atr = PA_CalcATR(context.signal_rates,InpATRPeriod);
   if(signal.direction > 0)
      return(PA_NormalizePrice(context.symbol,entry_price - (atr * InpStopAtrMultiplier)));
   return(PA_NormalizePrice(context.symbol,entry_price + (atr * InpStopAtrMultiplier)));
  }

double PA_DetermineTarget(const PA_Context &context,const PA_Signal &signal,const double entry_price,const double stop_price)
  {
   if(InpTargetModel == PA_TARGET_NEXT_LEVEL)
     {
      if(signal.direction > 0 && signal.target_price > entry_price)
         return(PA_NormalizePrice(context.symbol,signal.target_price));
      if(signal.direction < 0 && signal.target_price < entry_price)
         return(PA_NormalizePrice(context.symbol,signal.target_price));
     }

   const double risk = MathAbs(entry_price - stop_price);
   if(signal.direction > 0)
      return(PA_NormalizePrice(context.symbol,entry_price + (risk * InpRiskRewardRatio)));
   return(PA_NormalizePrice(context.symbol,entry_price - (risk * InpRiskRewardRatio)));
  }

void PA_ManageOpenTrade()
  {
   ulong ticket = 0;
   long position_type = -1;
   double open_price = 0.0;
   double stop_loss = 0.0;
   double take_profit = 0.0;
   double volume = 0.0;

   if(!PA_GetManagedPosition(_Symbol,InpMagicNumber,ticket,position_type,open_price,stop_loss,take_profit,volume))
      return;

   const double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   const double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   const double current_price = (position_type == POSITION_TYPE_BUY ? bid : ask);
   const double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   const double risk_distance = MathAbs(open_price - stop_loss);

   if(InpBreakEvenEnabled && risk_distance > 0.0)
     {
      const double reward_distance = MathAbs(current_price - open_price);
      if(reward_distance >= risk_distance * InpBreakEvenRR)
        {
         const double break_even = PA_NormalizePrice(_Symbol,open_price);
         const bool needs_update = (position_type == POSITION_TYPE_BUY ? stop_loss < break_even : stop_loss > break_even || stop_loss == 0.0);
         if(needs_update)
            g_trade.PositionModify(_Symbol,break_even,take_profit);
        }
     }

   if(InpTrailingEnabled && InpTrailingStopPoints > 0.0)
     {
      const double trail_distance = InpTrailingStopPoints * point;
      double new_stop = stop_loss;

      if(position_type == POSITION_TYPE_BUY)
        {
         new_stop = PA_NormalizePrice(_Symbol,bid - trail_distance);
         if(new_stop > stop_loss && new_stop < bid)
            g_trade.PositionModify(_Symbol,new_stop,take_profit);
        }
      else if(position_type == POSITION_TYPE_SELL)
        {
         new_stop = PA_NormalizePrice(_Symbol,ask + trail_distance);
         if((stop_loss == 0.0 || new_stop < stop_loss) && new_stop > ask)
            g_trade.PositionModify(_Symbol,new_stop,take_profit);
        }
     }
  }

bool PA_OpenTrade(const PA_Context &context,const PA_Signal &signal)
  {
   double current_volume = 0.0;
   double existing_open = 0.0;
   double existing_sl = 0.0;
   double existing_tp = 0.0;
   ulong existing_ticket = 0;
   long existing_type = -1;
   if(InpOnePositionPerSymbol && PA_GetManagedPosition(_Symbol,InpMagicNumber,existing_ticket,existing_type,existing_open,existing_sl,existing_tp,current_volume))
      return(false);

   const double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   const double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   const double entry_price = (signal.direction > 0 ? ask : bid);
   const double stop_price = PA_DetermineStop(context,signal,entry_price);
   const double take_profit = PA_DetermineTarget(context,signal,entry_price,stop_price);

   if(signal.direction > 0 && stop_price >= entry_price)
      return(false);
   if(signal.direction < 0 && stop_price <= entry_price)
      return(false);

   const double volume = PA_CalcPositionSize(_Symbol,entry_price,stop_price);
   if(volume <= 0.0)
      return(false);

   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpSlippagePoints);

   bool placed = false;
   if(signal.direction > 0)
      placed = g_trade.Buy(volume,_Symbol,0.0,stop_price,take_profit,signal.reason);
   else
      placed = g_trade.Sell(volume,_Symbol,0.0,stop_price,take_profit,signal.reason);

   if(placed)
     {
      g_trade_count_today++;
      g_last_trade_signal_time = signal.signal_time;
      if(InpDebugPrints)
         PrintFormat("PivotalAreasEA trade opened | %s | score=%d | matched=%s | entry=%.2f | sl=%.2f | tp=%.2f",
                     signal.reason,
                     signal.confluence_score,
                     signal.matched_levels,
                     entry_price,
                     stop_price,
                     take_profit);
     }
   else if(InpDebugPrints)
      PrintFormat("PivotalAreasEA trade rejected | retcode=%d | reason=%s",g_trade.ResultRetcode(),g_trade.ResultRetcodeDescription());

   return(placed);
  }

int OnInit()
  {
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade_day_key = PA_DayKey(TimeCurrent());
   return(INIT_SUCCEEDED);
  }

void OnTick()
  {
   PA_ResetDailyTradeCounter();
   PA_ManageOpenTrade();

   const datetime current_signal_bar = iTime(_Symbol,InpSignalTimeframe,0);
   if(current_signal_bar == 0 || current_signal_bar == g_last_signal_bar)
      return;

   g_last_signal_bar = current_signal_bar;

   if(!PA_IsSessionOpen())
      return;
   if(g_trade_count_today >= InpMaxTradesPerDay)
      return;

   PA_LevelFilters filters;
   PA_LoadEAFilters(filters);

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
      return;

   PA_Signal signal;
   if(!PA_EvaluateSignal(context,
                         InpTouchTolerancePoints,
                         InpMinConfluenceScore,
                         InpRejectionCloseRatio,
                         InpBreakoutBodyRatio,
                         InpRetestTimeoutBars,
                         InpMinBarrierRoomRisk,
                         signal))
      return;

   if(signal.signal_time == g_last_trade_signal_time)
      return;

   if(InpDebugPrints)
      PrintFormat("PivotalAreasEA signal | %s | score=%d | levels=%s",
                  signal.reason,
                  signal.confluence_score,
                  signal.matched_levels);

   PA_OpenTrade(context,signal);
  }
