#ifndef __PIVOTAL_AREAS_CORE_MQH__
#define __PIVOTAL_AREAS_CORE_MQH__

enum PA_LEVEL_KIND
  {
   PA_LEVEL_DAILY_PIVOT = 0,
   PA_LEVEL_DAILY_R1,
   PA_LEVEL_DAILY_S1,
   PA_LEVEL_DAILY_R2,
   PA_LEVEL_DAILY_S2,
   PA_LEVEL_WEEKLY_PIVOT,
   PA_LEVEL_WEEKLY_R1,
   PA_LEVEL_WEEKLY_S1,
   PA_LEVEL_WEEKLY_R2,
   PA_LEVEL_WEEKLY_S2,
   PA_LEVEL_DAILY_OPEN,
   PA_LEVEL_WEEKLY_OPEN,
   PA_LEVEL_DAILY_HIGH,
   PA_LEVEL_DAILY_LOW,
   PA_LEVEL_WEEKLY_HIGH,
   PA_LEVEL_WEEKLY_LOW,
   PA_LEVEL_DAILY_VWAP,
   PA_LEVEL_WEEKLY_VWAP,
   PA_LEVEL_SUPPLY_ZONE,
   PA_LEVEL_DEMAND_ZONE,
   PA_LEVEL_RESISTANCE,
   PA_LEVEL_SUPPORT
  };

enum PA_SIGNAL_KIND
  {
   PA_SIGNAL_NONE = 0,
   PA_SIGNAL_BULLISH_REJECTION,
   PA_SIGNAL_BEARISH_REJECTION,
   PA_SIGNAL_BULLISH_BREAK_RETEST,
   PA_SIGNAL_BEARISH_BREAK_RETEST
  };

struct PA_LevelFilters
  {
   bool use_daily_pivots;
   bool use_weekly_pivots;
   bool use_daily_open;
   bool use_weekly_open;
   bool use_daily_high_low;
   bool use_weekly_high_low;
   bool use_daily_vwap;
   bool use_weekly_vwap;
   bool use_supply_demand;
   bool use_support_resistance;
  };

struct PA_Level
  {
   string        id;
   string        label;
   PA_LEVEL_KIND kind;
   double        price;
   double        lower_bound;
   double        upper_bound;
   int           weight;
   bool          is_zone;
   bool          bullish_context;
   datetime      anchor_time;
  };

struct PA_Signal
  {
   PA_SIGNAL_KIND kind;
   int            direction;
   datetime       signal_time;
   double         reference_price;
   double         entry_price;
   double         stop_price;
   double         target_price;
   int            confluence_score;
   string         matched_levels;
   string         reason;
  };

class PA_Context
  {
public:
   string          symbol;
   ENUM_TIMEFRAMES signal_tf;
   ENUM_TIMEFRAMES structure_tf;
   int             digits;
   double          point;
   double          pip;
   MqlRates        signal_rates[];
   MqlRates        structure_rates[];
   PA_Level        levels[];

   void Reset(void)
     {
      symbol       = "";
      signal_tf    = PERIOD_CURRENT;
      structure_tf = PERIOD_CURRENT;
      digits       = 0;
      point        = 0.0;
      pip          = 0.0;
      ArrayResize(signal_rates,0);
      ArrayResize(structure_rates,0);
      ArrayResize(levels,0);
     }

   PA_Context(void)
     {
      Reset();
     }
  };

void PA_DefaultFilters(PA_LevelFilters &filters)
  {
   filters.use_daily_pivots      = true;
   filters.use_weekly_pivots     = true;
   filters.use_daily_open        = true;
   filters.use_weekly_open       = true;
   filters.use_daily_high_low    = true;
   filters.use_weekly_high_low   = true;
   filters.use_daily_vwap        = true;
   filters.use_weekly_vwap       = true;
   filters.use_supply_demand     = true;
   filters.use_support_resistance= true;
  }

void PA_ResetSignal(PA_Signal &signal)
  {
   signal.kind            = PA_SIGNAL_NONE;
   signal.direction       = 0;
   signal.signal_time     = 0;
   signal.reference_price = 0.0;
   signal.entry_price     = 0.0;
   signal.stop_price      = 0.0;
   signal.target_price    = 0.0;
   signal.confluence_score= 0;
   signal.matched_levels  = "";
   signal.reason          = "";
  }

double PA_PipSize(const string symbol)
  {
   const int digits = (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   const double point = SymbolInfoDouble(symbol,SYMBOL_POINT);
   if(digits == 3 || digits == 5)
      return(point * 10.0);
   return(point);
  }

double PA_NormalizePrice(const string symbol,const double price)
  {
   return(NormalizeDouble(price,(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS)));
  }

string PA_LevelKindLabel(const PA_LEVEL_KIND kind)
  {
   switch(kind)
     {
      case PA_LEVEL_DAILY_PIVOT:   return("Daily Pivot");
      case PA_LEVEL_DAILY_R1:      return("Daily R1");
      case PA_LEVEL_DAILY_S1:      return("Daily S1");
      case PA_LEVEL_DAILY_R2:      return("Daily R2");
      case PA_LEVEL_DAILY_S2:      return("Daily S2");
      case PA_LEVEL_WEEKLY_PIVOT:  return("Weekly Pivot");
      case PA_LEVEL_WEEKLY_R1:     return("Weekly R1");
      case PA_LEVEL_WEEKLY_S1:     return("Weekly S1");
      case PA_LEVEL_WEEKLY_R2:     return("Weekly R2");
      case PA_LEVEL_WEEKLY_S2:     return("Weekly S2");
      case PA_LEVEL_DAILY_OPEN:    return("Daily Open");
      case PA_LEVEL_WEEKLY_OPEN:   return("Weekly Open");
      case PA_LEVEL_DAILY_HIGH:    return("Daily High");
      case PA_LEVEL_DAILY_LOW:     return("Daily Low");
      case PA_LEVEL_WEEKLY_HIGH:   return("Weekly High");
      case PA_LEVEL_WEEKLY_LOW:    return("Weekly Low");
      case PA_LEVEL_DAILY_VWAP:    return("Daily VWAP");
      case PA_LEVEL_WEEKLY_VWAP:   return("Weekly VWAP");
      case PA_LEVEL_SUPPLY_ZONE:   return("Supply");
      case PA_LEVEL_DEMAND_ZONE:   return("Demand");
      case PA_LEVEL_RESISTANCE:    return("Resistance");
      case PA_LEVEL_SUPPORT:       return("Support");
     }
   return("Level");
  }

string PA_SignalKindLabel(const PA_SIGNAL_KIND kind)
  {
   switch(kind)
     {
      case PA_SIGNAL_BULLISH_REJECTION:    return("Bullish Rejection");
      case PA_SIGNAL_BEARISH_REJECTION:    return("Bearish Rejection");
      case PA_SIGNAL_BULLISH_BREAK_RETEST: return("Bullish Break-Retest");
      case PA_SIGNAL_BEARISH_BREAK_RETEST: return("Bearish Break-Retest");
      default:                             return("No Signal");
     }
  }

bool PA_IsDemandSupportLevel(const PA_LEVEL_KIND kind)
  {
   return(kind == PA_LEVEL_DEMAND_ZONE || kind == PA_LEVEL_SUPPORT);
  }

bool PA_IsSupplyResistanceLevel(const PA_LEVEL_KIND kind)
  {
   return(kind == PA_LEVEL_SUPPLY_ZONE || kind == PA_LEVEL_RESISTANCE);
  }

bool PA_IsBullishBarrierLevel(const PA_LEVEL_KIND kind)
  {
   switch(kind)
     {
      case PA_LEVEL_DEMAND_ZONE:
      case PA_LEVEL_SUPPORT:
      case PA_LEVEL_DAILY_LOW:
      case PA_LEVEL_WEEKLY_LOW:
      case PA_LEVEL_DAILY_S1:
      case PA_LEVEL_DAILY_S2:
      case PA_LEVEL_WEEKLY_S1:
      case PA_LEVEL_WEEKLY_S2:
         return(true);
      default:
         return(false);
     }
  }

bool PA_IsBearishBarrierLevel(const PA_LEVEL_KIND kind)
  {
   switch(kind)
     {
      case PA_LEVEL_SUPPLY_ZONE:
      case PA_LEVEL_RESISTANCE:
      case PA_LEVEL_DAILY_HIGH:
      case PA_LEVEL_WEEKLY_HIGH:
      case PA_LEVEL_DAILY_R1:
      case PA_LEVEL_DAILY_R2:
      case PA_LEVEL_WEEKLY_R1:
      case PA_LEVEL_WEEKLY_R2:
         return(true);
      default:
         return(false);
     }
  }

bool PA_IsSourceLevelAllowed(const PA_Level &level,const int direction)
  {
   if(direction > 0 && PA_IsSupplyResistanceLevel(level.kind))
      return(false);
   if(direction < 0 && PA_IsDemandSupportLevel(level.kind))
      return(false);
   return(true);
  }

bool PA_LoadRates(const string symbol,const ENUM_TIMEFRAMES timeframe,const int bars,MqlRates &rates[])
  {
   ArraySetAsSeries(rates,true);
   const int copied = CopyRates(symbol,timeframe,0,bars,rates);
   return(copied >= bars);
  }

double PA_TrueRange(const MqlRates &current_bar,const MqlRates &older_bar)
  {
   const double high_low   = current_bar.high - current_bar.low;
   const double high_close = MathAbs(current_bar.high - older_bar.close);
   const double low_close  = MathAbs(current_bar.low  - older_bar.close);
   return(MathMax(high_low,MathMax(high_close,low_close)));
  }

double PA_CalcATR(const MqlRates &rates[],const int period)
  {
   const int size = ArraySize(rates);
   if(size <= period + 1)
      return(0.0);

   double total = 0.0;
   int count = 0;
   for(int i = 1; i <= period; ++i)
     {
      total += PA_TrueRange(rates[i],rates[i + 1]);
      count++;
     }
   if(count == 0)
      return(0.0);
   return(total / (double)count);
  }

bool PA_IsDuplicateLevel(const PA_Level &levels[],
                         const PA_LEVEL_KIND kind,
                         const double price,
                         const datetime anchor_time,
                         const double tolerance)
  {
   for(int i = 0; i < ArraySize(levels); ++i)
     {
      if(levels[i].kind != kind)
         continue;
      if(anchor_time != 0 && levels[i].anchor_time != anchor_time)
         continue;
      if(MathAbs(levels[i].price - price) <= tolerance)
         return(true);
     }
   return(false);
  }

void PA_AddLevel(PA_Level &levels[],
                 const string id,
                 const string label,
                 const PA_LEVEL_KIND kind,
                 const double price,
                 const double lower_bound,
                 const double upper_bound,
                 const int weight,
                 const bool is_zone,
                 const bool bullish_context,
                 const datetime anchor_time,
                 const double duplicate_tolerance)
  {
   if(PA_IsDuplicateLevel(levels,kind,price,anchor_time,duplicate_tolerance))
      return;

   const int next = ArraySize(levels);
   ArrayResize(levels,next + 1);

   levels[next].id              = id;
   levels[next].label           = label;
   levels[next].kind            = kind;
   levels[next].price           = price;
   levels[next].lower_bound     = lower_bound;
   levels[next].upper_bound     = upper_bound;
   levels[next].weight          = weight;
   levels[next].is_zone         = is_zone;
   levels[next].bullish_context = bullish_context;
   levels[next].anchor_time     = anchor_time;
  }

bool PA_CalcPivotSet(const string symbol,
                     const ENUM_TIMEFRAMES timeframe,
                     double &pivot,
                     double &r1,
                     double &s1,
                     double &r2,
                     double &s2)
  {
   MqlRates bars[];
   ArraySetAsSeries(bars,true);
   if(CopyRates(symbol,timeframe,1,1,bars) < 1)
      return(false);

   const double high  = bars[0].high;
   const double low   = bars[0].low;
   const double close = bars[0].close;

   pivot = (high + low + close) / 3.0;
   r1    = (2.0 * pivot) - low;
   s1    = (2.0 * pivot) - high;
   r2    = pivot + (high - low);
   s2    = pivot - (high - low);
   return(true);
  }

double PA_CalcAnchoredVWAP(const string symbol,const datetime start_time)
  {
   MqlRates rates[];
   ArraySetAsSeries(rates,false);
   const int copied = CopyRates(symbol,PERIOD_M1,start_time,TimeCurrent(),rates);
   if(copied <= 0)
      return(0.0);

   double price_volume = 0.0;
   double volume_sum   = 0.0;
   for(int i = 0; i < copied; ++i)
     {
      const double volume = (rates[i].real_volume > 0 ? (double)rates[i].real_volume : (double)rates[i].tick_volume);
      if(volume <= 0.0)
         continue;

      const double typical_price = (rates[i].high + rates[i].low + rates[i].close) / 3.0;
      price_volume += typical_price * volume;
      volume_sum   += volume;
     }

   if(volume_sum <= 0.0)
      return(0.0);
   return(price_volume / volume_sum);
  }

int PA_ConfluenceScore(const PA_Level &levels[],const double price,const double tolerance,string &matched_labels)
  {
   int score = 0;
   matched_labels = "";

   for(int i = 0; i < ArraySize(levels); ++i)
     {
      const bool inside_zone = (price >= levels[i].lower_bound - tolerance && price <= levels[i].upper_bound + tolerance);
      if(!inside_zone)
         continue;

      score += levels[i].weight;
      if(StringLen(matched_labels) > 0)
         matched_labels += ", ";
      matched_labels += levels[i].label;
     }
   return(score);
  }

bool PA_FindNextDirectionalLevel(const PA_Level &levels[],const double reference_price,const int direction,PA_Level &next_level)
  {
   bool found = false;
   double best_distance = DBL_MAX;

   for(int i = 0; i < ArraySize(levels); ++i)
     {
      const double distance = levels[i].price - reference_price;
      if(direction > 0 && distance <= 0.0)
         continue;
      if(direction < 0 && distance >= 0.0)
         continue;

      const double absolute_distance = MathAbs(distance);
      if(absolute_distance < best_distance)
        {
         best_distance = absolute_distance;
         next_level = levels[i];
         found = true;
        }
     }

   return(found);
  }

bool PA_FindNearestBarrierLevel(const PA_Level &levels[],const double reference_price,const int direction,PA_Level &barrier_level)
  {
   bool found = false;
   double best_distance = DBL_MAX;

   for(int i = 0; i < ArraySize(levels); ++i)
     {
      const bool is_barrier = (direction > 0 ? PA_IsBearishBarrierLevel(levels[i].kind) : PA_IsBullishBarrierLevel(levels[i].kind));
      if(!is_barrier)
         continue;

      const double distance = levels[i].price - reference_price;
      if(direction > 0 && distance <= 0.0)
         continue;
      if(direction < 0 && distance >= 0.0)
         continue;

      const double absolute_distance = MathAbs(distance);
      if(absolute_distance < best_distance)
        {
         best_distance = absolute_distance;
         barrier_level = levels[i];
         found = true;
        }
     }

   return(found);
  }

bool PA_PrepareCandidateTrade(const PA_Level &levels[],
                              const int direction,
                              const double entry_price,
                              const double stop_price,
                              const double min_barrier_room_risk,
                              double &target_price)
  {
   const double risk_distance = MathAbs(entry_price - stop_price);
   if(risk_distance <= 0.0)
      return(false);

   PA_Level barrier_level;
   if(PA_FindNearestBarrierLevel(levels,entry_price,direction,barrier_level))
     {
      const double room_to_barrier = MathAbs(barrier_level.price - entry_price);
      if(room_to_barrier < risk_distance * min_barrier_room_risk)
         return(false);

      target_price = barrier_level.price;
      return(true);
     }

   if(direction > 0)
      target_price = entry_price + (risk_distance * 2.0);
   else
      target_price = entry_price - (risk_distance * 2.0);
   return(true);
  }

bool PA_CandleTouchesLevel(const MqlRates &bar,const PA_Level &level,const double tolerance)
  {
   return(bar.high >= level.lower_bound - tolerance && bar.low <= level.upper_bound + tolerance);
  }

bool PA_IsBullishRejection(const MqlRates &bar,const PA_Level &level,const double tolerance,const double min_close_ratio)
  {
   if(!PA_CandleTouchesLevel(bar,level,tolerance))
      return(false);

   const double range = bar.high - bar.low;
   if(range <= 0.0)
      return(false);

   const double close_location = (bar.close - bar.low) / range;
   return(bar.close > bar.open &&
          bar.close >= level.price &&
          close_location >= min_close_ratio);
  }

bool PA_IsBearishRejection(const MqlRates &bar,const PA_Level &level,const double tolerance,const double min_close_ratio)
  {
   if(!PA_CandleTouchesLevel(bar,level,tolerance))
      return(false);

   const double range = bar.high - bar.low;
   if(range <= 0.0)
      return(false);

   const double close_location = (bar.high - bar.close) / range;
   return(bar.close < bar.open &&
          bar.close <= level.price &&
          close_location >= min_close_ratio);
  }

bool PA_IsBullishBreakRetest(const MqlRates &break_bar,
                             const MqlRates &retest_bar,
                             const PA_Level &level,
                             const double tolerance,
                             const double min_breakout_body_ratio)
  {
   const double break_range = break_bar.high - break_bar.low;
   if(break_range <= 0.0)
      return(false);

   const double break_body_ratio = MathAbs(break_bar.close - break_bar.open) / break_range;
   if(break_bar.close <= level.upper_bound + tolerance || break_body_ratio < min_breakout_body_ratio)
      return(false);

   return(retest_bar.low <= level.upper_bound + tolerance &&
          retest_bar.close > level.upper_bound &&
          retest_bar.close > retest_bar.open);
  }

bool PA_IsBearishBreakRetest(const MqlRates &break_bar,
                             const MqlRates &retest_bar,
                             const PA_Level &level,
                             const double tolerance,
                             const double min_breakout_body_ratio)
  {
   const double break_range = break_bar.high - break_bar.low;
   if(break_range <= 0.0)
      return(false);

   const double break_body_ratio = MathAbs(break_bar.close - break_bar.open) / break_range;
   if(break_bar.close >= level.lower_bound - tolerance || break_body_ratio < min_breakout_body_ratio)
      return(false);

   return(retest_bar.high >= level.lower_bound - tolerance &&
          retest_bar.close < level.lower_bound &&
          retest_bar.close < retest_bar.open);
  }

void PA_AddPivotLevels(const string symbol,const PA_LevelFilters &filters,PA_Level &levels[],const double duplicate_tolerance)
  {
   double pivot = 0.0, r1 = 0.0, s1 = 0.0, r2 = 0.0, s2 = 0.0;

   if(filters.use_daily_pivots && PA_CalcPivotSet(symbol,PERIOD_D1,pivot,r1,s1,r2,s2))
     {
      const datetime anchor = iTime(symbol,PERIOD_D1,0);
      PA_AddLevel(levels,"daily_pivot","Daily Pivot",PA_LEVEL_DAILY_PIVOT,pivot,pivot,pivot,4,false,true,anchor,duplicate_tolerance);
      PA_AddLevel(levels,"daily_r1","Daily R1",PA_LEVEL_DAILY_R1,r1,r1,r1,3,false,false,anchor,duplicate_tolerance);
      PA_AddLevel(levels,"daily_s1","Daily S1",PA_LEVEL_DAILY_S1,s1,s1,s1,3,false,true,anchor,duplicate_tolerance);
      PA_AddLevel(levels,"daily_r2","Daily R2",PA_LEVEL_DAILY_R2,r2,r2,r2,2,false,false,anchor,duplicate_tolerance);
      PA_AddLevel(levels,"daily_s2","Daily S2",PA_LEVEL_DAILY_S2,s2,s2,s2,2,false,true,anchor,duplicate_tolerance);
     }

   if(filters.use_weekly_pivots && PA_CalcPivotSet(symbol,PERIOD_W1,pivot,r1,s1,r2,s2))
     {
      const datetime anchor = iTime(symbol,PERIOD_W1,0);
      PA_AddLevel(levels,"weekly_pivot","Weekly Pivot",PA_LEVEL_WEEKLY_PIVOT,pivot,pivot,pivot,6,false,true,anchor,duplicate_tolerance);
      PA_AddLevel(levels,"weekly_r1","Weekly R1",PA_LEVEL_WEEKLY_R1,r1,r1,r1,5,false,false,anchor,duplicate_tolerance);
      PA_AddLevel(levels,"weekly_s1","Weekly S1",PA_LEVEL_WEEKLY_S1,s1,s1,s1,5,false,true,anchor,duplicate_tolerance);
      PA_AddLevel(levels,"weekly_r2","Weekly R2",PA_LEVEL_WEEKLY_R2,r2,r2,r2,4,false,false,anchor,duplicate_tolerance);
      PA_AddLevel(levels,"weekly_s2","Weekly S2",PA_LEVEL_WEEKLY_S2,s2,s2,s2,4,false,true,anchor,duplicate_tolerance);
     }
  }

void PA_AddOpenHighLowLevels(const string symbol,const PA_LevelFilters &filters,PA_Level &levels[],const double duplicate_tolerance)
  {
   if(filters.use_daily_open)
     {
      const double daily_open = iOpen(symbol,PERIOD_D1,0);
      const datetime anchor = iTime(symbol,PERIOD_D1,0);
      PA_AddLevel(levels,"daily_open","Daily Open",PA_LEVEL_DAILY_OPEN,daily_open,daily_open,daily_open,4,false,true,anchor,duplicate_tolerance);
     }

   if(filters.use_weekly_open)
     {
      const double weekly_open = iOpen(symbol,PERIOD_W1,0);
      const datetime anchor = iTime(symbol,PERIOD_W1,0);
      PA_AddLevel(levels,"weekly_open","Weekly Open",PA_LEVEL_WEEKLY_OPEN,weekly_open,weekly_open,weekly_open,6,false,true,anchor,duplicate_tolerance);
     }

   if(filters.use_daily_high_low)
     {
      const double daily_high = iHigh(symbol,PERIOD_D1,0);
      const double daily_low  = iLow(symbol,PERIOD_D1,0);
      const datetime anchor   = iTime(symbol,PERIOD_D1,0);
      PA_AddLevel(levels,"daily_high","Daily High",PA_LEVEL_DAILY_HIGH,daily_high,daily_high,daily_high,5,false,false,anchor,duplicate_tolerance);
      PA_AddLevel(levels,"daily_low","Daily Low",PA_LEVEL_DAILY_LOW,daily_low,daily_low,daily_low,5,false,true,anchor,duplicate_tolerance);
     }

   if(filters.use_weekly_high_low)
     {
      const double weekly_high = iHigh(symbol,PERIOD_W1,0);
      const double weekly_low  = iLow(symbol,PERIOD_W1,0);
      const datetime anchor    = iTime(symbol,PERIOD_W1,0);
      PA_AddLevel(levels,"weekly_high","Weekly High",PA_LEVEL_WEEKLY_HIGH,weekly_high,weekly_high,weekly_high,7,false,false,anchor,duplicate_tolerance);
      PA_AddLevel(levels,"weekly_low","Weekly Low",PA_LEVEL_WEEKLY_LOW,weekly_low,weekly_low,weekly_low,7,false,true,anchor,duplicate_tolerance);
     }
  }

void PA_AddVWAPLevels(const string symbol,const PA_LevelFilters &filters,PA_Level &levels[],const double duplicate_tolerance)
  {
   if(filters.use_daily_vwap)
     {
      const datetime day_start = iTime(symbol,PERIOD_D1,0);
      const double daily_vwap = PA_CalcAnchoredVWAP(symbol,day_start);
      if(daily_vwap > 0.0)
         PA_AddLevel(levels,"daily_vwap","Daily VWAP",PA_LEVEL_DAILY_VWAP,daily_vwap,daily_vwap,daily_vwap,5,false,true,day_start,duplicate_tolerance);
     }

   if(filters.use_weekly_vwap)
     {
      const datetime week_start = iTime(symbol,PERIOD_W1,0);
      const double weekly_vwap = PA_CalcAnchoredVWAP(symbol,week_start);
      if(weekly_vwap > 0.0)
         PA_AddLevel(levels,"weekly_vwap","Weekly VWAP",PA_LEVEL_WEEKLY_VWAP,weekly_vwap,weekly_vwap,weekly_vwap,7,false,true,week_start,duplicate_tolerance);
     }
  }

bool PA_IsSwingHigh(const MqlRates &rates[],const int index,const int strength)
  {
   for(int step = 1; step <= strength; ++step)
     {
      if(rates[index].high <= rates[index - step].high || rates[index].high <= rates[index + step].high)
         return(false);
     }
   return(true);
  }

bool PA_IsSwingLow(const MqlRates &rates[],const int index,const int strength)
  {
   for(int step = 1; step <= strength; ++step)
     {
      if(rates[index].low >= rates[index - step].low || rates[index].low >= rates[index + step].low)
         return(false);
     }
   return(true);
  }

void PA_AddStructureLevels(const string symbol,
                           const MqlRates &rates[],
                           const int lookback,
                           const int swing_strength,
                           const int atr_period,
                           const double zone_atr_multiplier,
                           const PA_LevelFilters &filters,
                           PA_Level &levels[],
                           const double duplicate_tolerance)
  {
   if(!filters.use_supply_demand && !filters.use_support_resistance)
      return;

   const int size = ArraySize(rates);
   if(size <= swing_strength * 2 + 5)
      return;

   const double atr = PA_CalcATR(rates,atr_period);
   const double zone_half_width = MathMax(atr * zone_atr_multiplier, duplicate_tolerance * 2.0);
   int zones_added = 0;

   for(int i = swing_strength + 1; i < MathMin(size - swing_strength - 1,lookback); ++i)
     {
      if(PA_IsSwingHigh(rates,i,swing_strength))
        {
         const double price = rates[i].high;
         const datetime anchor = rates[i].time;
         if(filters.use_support_resistance)
            PA_AddLevel(levels,
                        "resistance_" + IntegerToString((int)anchor),
                        "Resistance",
                        PA_LEVEL_RESISTANCE,
                        price,
                        price,
                        price,
                        4,
                        false,
                        false,
                        anchor,
                        duplicate_tolerance);

         if(filters.use_supply_demand)
            PA_AddLevel(levels,
                        "supply_" + IntegerToString((int)anchor),
                        "Supply",
                        PA_LEVEL_SUPPLY_ZONE,
                        price,
                        price - zone_half_width,
                        price + zone_half_width,
                        5,
                        true,
                        false,
                        anchor,
                        duplicate_tolerance);

         zones_added++;
        }

      if(PA_IsSwingLow(rates,i,swing_strength))
        {
         const double price = rates[i].low;
         const datetime anchor = rates[i].time;
         if(filters.use_support_resistance)
            PA_AddLevel(levels,
                        "support_" + IntegerToString((int)anchor),
                        "Support",
                        PA_LEVEL_SUPPORT,
                        price,
                        price,
                        price,
                        4,
                        false,
                        true,
                        anchor,
                        duplicate_tolerance);

         if(filters.use_supply_demand)
            PA_AddLevel(levels,
                        "demand_" + IntegerToString((int)anchor),
                        "Demand",
                        PA_LEVEL_DEMAND_ZONE,
                        price,
                        price - zone_half_width,
                        price + zone_half_width,
                        5,
                        true,
                        true,
                        anchor,
                        duplicate_tolerance);

         zones_added++;
        }

      if(zones_added >= 20)
         break;
     }
  }

bool PA_BuildContext(const string symbol,
                     const ENUM_TIMEFRAMES signal_tf,
                     const ENUM_TIMEFRAMES structure_tf,
                     const int signal_bars,
                     const int structure_lookback,
                     const int swing_strength,
                     const int atr_period,
                     const double zone_atr_multiplier,
                     const PA_LevelFilters &filters,
                     PA_Context &context)
  {
   context.symbol       = symbol;
   context.signal_tf    = signal_tf;
   context.structure_tf = structure_tf;
   context.digits       = (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   context.point        = SymbolInfoDouble(symbol,SYMBOL_POINT);
   context.pip          = PA_PipSize(symbol);

   ArrayResize(context.levels,0);
   ArrayResize(context.signal_rates,0);
   ArrayResize(context.structure_rates,0);

   if(!PA_LoadRates(symbol,signal_tf,signal_bars,context.signal_rates))
      return(false);
   if(!PA_LoadRates(symbol,structure_tf,MathMax(structure_lookback + 50,atr_period + 10),context.structure_rates))
      return(false);

   const double duplicate_tolerance = MathMax(context.pip * 3.0,context.point * 20.0);

   PA_AddPivotLevels(symbol,filters,context.levels,duplicate_tolerance);
   PA_AddOpenHighLowLevels(symbol,filters,context.levels,duplicate_tolerance);
   PA_AddVWAPLevels(symbol,filters,context.levels,duplicate_tolerance);
   PA_AddStructureLevels(symbol,
                         context.structure_rates,
                         structure_lookback,
                         swing_strength,
                         atr_period,
                         zone_atr_multiplier,
                         filters,
                         context.levels,
                         duplicate_tolerance);

   return(ArraySize(context.levels) > 0);
  }

bool PA_SelectHigherScore(const int score,const PA_Signal &candidate,const PA_Signal &current_best)
  {
   if(score > current_best.confluence_score)
      return(true);

   if(score == current_best.confluence_score && MathAbs(candidate.entry_price - candidate.reference_price) < MathAbs(current_best.entry_price - current_best.reference_price))
      return(true);

   return(false);
  }

bool PA_EvaluateSignal(const PA_Context &context,
                       const double touch_tolerance_points,
                       const int min_confluence_score,
                       const double min_rejection_close_ratio,
                       const double min_breakout_body_ratio,
                       const int retest_timeout_bars,
                       const double min_barrier_room_risk,
                       PA_Signal &signal)
  {
   PA_ResetSignal(signal);

   if(ArraySize(context.signal_rates) < retest_timeout_bars + 3)
      return(false);

   const double tolerance = touch_tolerance_points * context.point;
   const MqlRates trigger_bar = context.signal_rates[1];
   for(int i = 0; i < ArraySize(context.levels); ++i)
     {
      const PA_Level level = context.levels[i];
      string matched = "";

      if(PA_IsSourceLevelAllowed(level,1) && PA_IsBullishRejection(trigger_bar,level,tolerance,min_rejection_close_ratio))
        {
         PA_Signal candidate;
         PA_ResetSignal(candidate);
         candidate.kind            = PA_SIGNAL_BULLISH_REJECTION;
         candidate.direction       = 1;
         candidate.signal_time     = trigger_bar.time;
         candidate.reference_price = level.price;
         candidate.entry_price     = trigger_bar.close;
         candidate.stop_price      = level.lower_bound - tolerance;
         candidate.confluence_score= PA_ConfluenceScore(context.levels,level.price,tolerance,matched);
         candidate.matched_levels  = matched;
         candidate.reason          = StringFormat("%s at %s",PA_SignalKindLabel(candidate.kind),level.label);
         if(!PA_PrepareCandidateTrade(context.levels,candidate.direction,candidate.entry_price,candidate.stop_price,min_barrier_room_risk,candidate.target_price))
            continue;

         if(candidate.confluence_score >= min_confluence_score && PA_SelectHigherScore(candidate.confluence_score,candidate,signal))
            signal = candidate;
        }

      if(PA_IsSourceLevelAllowed(level,-1) && PA_IsBearishRejection(trigger_bar,level,tolerance,min_rejection_close_ratio))
        {
         PA_Signal candidate;
         PA_ResetSignal(candidate);
         candidate.kind            = PA_SIGNAL_BEARISH_REJECTION;
         candidate.direction       = -1;
         candidate.signal_time     = trigger_bar.time;
         candidate.reference_price = level.price;
         candidate.entry_price     = trigger_bar.close;
         candidate.stop_price      = level.upper_bound + tolerance;
         candidate.confluence_score= PA_ConfluenceScore(context.levels,level.price,tolerance,matched);
         candidate.matched_levels  = matched;
         candidate.reason          = StringFormat("%s at %s",PA_SignalKindLabel(candidate.kind),level.label);
         if(!PA_PrepareCandidateTrade(context.levels,candidate.direction,candidate.entry_price,candidate.stop_price,min_barrier_room_risk,candidate.target_price))
            continue;

         if(candidate.confluence_score >= min_confluence_score && PA_SelectHigherScore(candidate.confluence_score,candidate,signal))
            signal = candidate;
        }

      for(int lookback = 2; lookback <= retest_timeout_bars + 1; ++lookback)
        {
         const MqlRates break_bar = context.signal_rates[lookback];

         if(PA_IsSourceLevelAllowed(level,1) && PA_IsBullishBreakRetest(break_bar,trigger_bar,level,tolerance,min_breakout_body_ratio))
           {
            PA_Signal candidate;
            PA_ResetSignal(candidate);
            candidate.kind            = PA_SIGNAL_BULLISH_BREAK_RETEST;
            candidate.direction       = 1;
            candidate.signal_time     = trigger_bar.time;
            candidate.reference_price = level.price;
            candidate.entry_price     = trigger_bar.close;
            candidate.stop_price      = level.lower_bound - tolerance;
            candidate.confluence_score= PA_ConfluenceScore(context.levels,level.price,tolerance,matched);
            candidate.matched_levels  = matched;
            candidate.reason          = StringFormat("%s through %s",PA_SignalKindLabel(candidate.kind),level.label);
            if(!PA_PrepareCandidateTrade(context.levels,candidate.direction,candidate.entry_price,candidate.stop_price,min_barrier_room_risk,candidate.target_price))
               continue;

            if(candidate.confluence_score >= min_confluence_score && PA_SelectHigherScore(candidate.confluence_score,candidate,signal))
               signal = candidate;
            break;
           }

         if(PA_IsSourceLevelAllowed(level,-1) && PA_IsBearishBreakRetest(break_bar,trigger_bar,level,tolerance,min_breakout_body_ratio))
           {
            PA_Signal candidate;
            PA_ResetSignal(candidate);
            candidate.kind            = PA_SIGNAL_BEARISH_BREAK_RETEST;
            candidate.direction       = -1;
            candidate.signal_time     = trigger_bar.time;
            candidate.reference_price = level.price;
            candidate.entry_price     = trigger_bar.close;
            candidate.stop_price      = level.upper_bound + tolerance;
            candidate.confluence_score= PA_ConfluenceScore(context.levels,level.price,tolerance,matched);
            candidate.matched_levels  = matched;
            candidate.reason          = StringFormat("%s through %s",PA_SignalKindLabel(candidate.kind),level.label);
            if(!PA_PrepareCandidateTrade(context.levels,candidate.direction,candidate.entry_price,candidate.stop_price,min_barrier_room_risk,candidate.target_price))
               continue;

            if(candidate.confluence_score >= min_confluence_score && PA_SelectHigherScore(candidate.confluence_score,candidate,signal))
               signal = candidate;
            break;
           }
        }
     }

   return(signal.kind != PA_SIGNAL_NONE);
  }

#endif
