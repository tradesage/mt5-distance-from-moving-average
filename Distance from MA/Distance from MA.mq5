//+------------------------------------------------------------------+
//|                                             Distance from MA.mq5 |
//|                                Copyright 2019, Leonardo Sposina. |
//|           https://www.mql5.com/en/users/leonardo_splinter/seller |
//+------------------------------------------------------------------+

input int Evaluated_Period = 100; // Evaluated Period
input int MA_Period = 20; // Moving Average Period
input ENUM_MA_METHOD MA_Method = MODE_SMA; //Moving Average Method

string indicatorLabel = "";
int movingAverageHandle = 0;
int minimumPeriod = 0;
double colorBuffer[];
double priceDistanceBuffer[];
double movingAverageBuffer[];
enum ENUM_LEVEL_TYPE {LEVEL_MAX, LEVEL_AVERAGE, LEVEL_MIN};

int OnInit() {
   SetIndexBuffer(0, priceDistanceBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, colorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, movingAverageBuffer, INDICATOR_CALCULATIONS);
   indicatorLabel = StringFormat("Distance from %s(%d)", getMovigAverageMethodName(MA_Method), MA_Period);
   PlotIndexSetString(0, PLOT_LABEL, indicatorLabel);
   IndicatorSetString(INDICATOR_SHORTNAME, indicatorLabel);
   IndicatorSetInteger(INDICATOR_LEVELS, 4);
   movingAverageHandle = iMA(_Symbol, _Period, MA_Period, 0, MA_Method, PRICE_CLOSE);
   minimumPeriod = Evaluated_Period + MA_Period;
   return(INIT_SUCCEEDED);
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
                const int &spread[]) {

   ArrayInitialize(priceDistanceBuffer, EMPTY_VALUE);
   ArrayInitialize(movingAverageBuffer, EMPTY_VALUE);
   if (rates_total > minimumPeriod) {
      if (movingAverageHandle > 0 && Evaluated_Period > 0 && !IsStopped()) {
         if (CopyBuffer(movingAverageHandle, 0, 0, Evaluated_Period, movingAverageBuffer) > 0) {
            int firstBar = rates_total - Evaluated_Period;
            double highList[];
            double lowList[];
            int highCount = 0;
            int lowCount = 0;
            for (int i = firstBar; i < rates_total; i++) {
               double movingAverageValue = movingAverageBuffer[i];
               double highDiff = MathAbs(movingAverageValue - high[i]);
               double lowDiff = MathAbs(movingAverageValue - low[i]);
               if (highDiff >= lowDiff && high[i] > movingAverageValue) {
                  priceDistanceBuffer[i] = highDiff;
                  colorBuffer[i] = 0.0;
                  ArrayResize(highList, highCount + 1);
                  highList[highCount++] = highDiff;
               } else if (highDiff <= lowDiff && low[i] < movingAverageValue) {
                  priceDistanceBuffer[i] = -lowDiff;
                  colorBuffer[i] = 1.0;
                  ArrayResize(lowList, lowCount + 1);
                  lowList[lowCount++] = -lowDiff;
               }
            }
            setIndicatorLevel(highList, LEVEL_MAX, 0);
            setIndicatorLevel(highList, LEVEL_AVERAGE, 1);
            setIndicatorLevel(lowList, LEVEL_AVERAGE, 2);
            setIndicatorLevel(lowList, LEVEL_MIN, 3);
         }
      }
   } else {
      Print(StringFormat("This timeframe doesn't have enough timeseries to be evaluated. It must be greater than %d.", minimumPeriod));     
   }
   ChartRedraw();
   return(rates_total);
}

string getMovigAverageMethodName(ENUM_MA_METHOD method) {
   string result = EnumToString(method);
   return StringSubstr(result, 5);
}

void setIndicatorLevel(double &arr[], ENUM_LEVEL_TYPE levelType, int index) {
   double value = 0;
   string text = "";
   int arrSize = ArraySize(arr);
   
   if (arrSize > 0) {
      if (levelType == LEVEL_MAX) {
         int indexValue = ArrayMaximum(arr);
         value = arr[indexValue];
         IndicatorSetDouble(INDICATOR_MAXIMUM, value);
         text = "Above distance";
      } else if (levelType == LEVEL_AVERAGE) {
         double valueSum = 0;
         for (int i = 0; i < arrSize; i++) {
            valueSum += arr[i];
         }
         value = valueSum / arrSize;
         text = "Average distance";
      } else if (levelType == LEVEL_MIN) {
         int indexValue = ArrayMinimum(arr);
         value = arr[indexValue];
         text = "Below distance";
         IndicatorSetDouble(INDICATOR_MINIMUM, value);
      }
      IndicatorSetDouble(INDICATOR_LEVELVALUE, index, value);
      IndicatorSetString(INDICATOR_LEVELTEXT, index, text);
   }
}