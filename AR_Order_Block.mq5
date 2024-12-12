//+------------------------------------------------------------------+
//|                                         AR_Order_Block.mq5       |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Andrukas8"
#property link      "https://github.com/Andrukas8/AR_Order_Block"
#property version   "1.1"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot UP
#property indicator_label1  "Up"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLimeGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3

//--- plot DN
#property indicator_label2  "Down"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrTomato
#property indicator_style2  STYLE_SOLID
#property indicator_width2  3

// -- indicator inputs
input bool rectanglesToggle = true;           // Add Order Block Rectangles
input bool fvgToggle = true;                  // Add Fair Value Gap Rectangles
input int LOOKBACK = 2000;                    // How many candles to lookback
input color obBearishColor = clrDarkGreen;    // Color of Bearish OB Rectangle
input color obBullishColor = clrDarkRed;      // Color of Bullish OB Rectangle
input color fvgColor = clrDarkSlateGray;      // Color of Bullish OB Rectangle

//--- indicator buffers
double BufferUP[];
double BufferDN[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,BufferUP,INDICATOR_DATA);
   SetIndexBuffer(1,BufferDN,INDICATOR_DATA);
//--- setting a code from the Wingdings charset as the property of PLOT_ARROW

   PlotIndexSetInteger(0,PLOT_ARROW,159); // Arrow up
   PlotIndexSetInteger(1,PLOT_ARROW,159); // Arrow Down

   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,40);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,-40);

//--- setting indicator parameters
   IndicatorSetString(INDICATOR_SHORTNAME,"OrderBlock");
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
//--- setting buffer arrays as timeseries
   ArraySetAsSeries(BufferUP,true);
   ArraySetAsSeries(BufferDN,true);

//---

   if(!removeRectangles())
      Print(__FUNCTION__, " Failed...");

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
//--- Checking the minimum number of bars for calculation

//Print(rates_total," ", prev_calculated);

   if(rates_total > prev_calculated)
     {
      if(!removeRectangles())
         Print(__FUNCTION__, " Failed...");

      if(rates_total<3)
         return 0;

      //--- Checking and calculating the number of bars

      ArrayInitialize(BufferUP,EMPTY_VALUE);
      ArrayInitialize(BufferDN,EMPTY_VALUE);

      //--- Indexing arrays as timeseries
      ArraySetAsSeries(low,true);
      ArraySetAsSeries(high,true);
      ArraySetAsSeries(close,true);
      ArraySetAsSeries(open,true);
      ArraySetAsSeries(time,true);

      //--- Calculating the indicator

      for(int i=LOOKBACK; i>1 && !IsStopped(); i--)
        {
         bool strike_up=false;
         bool strike_dn=false;

         // OB
         if(
            (
               low[i] < low[i+1]
               && low[i] < low[i-1]
               && high[i] < low[i-2]
               && open[i-1] < high[i]
               && close[i-1] > low[i-2]
            )
            ||
            (
               low[i+1] < low[i+2]
               && low[i+1] < low[i]
               && high[i+1] > low[i-1]
               && high[i] < high[i-2]
            )
         )
            strike_up = true; // GREEN

         if(
            (
               high[i] > high[i+1]
               && high[i] > high[i-1]
               && low[i] > high[i-2]
               && open[i-1] > low[i]
               && close[i-1] < high[i-2]
            )
            ||
            (
               high[i+1] > high[i+2]
               && high[i+1] > high[i]
               && low[i+1] < high[i-1]
               && low[i] > high[i-2]
            )

         )
            strike_dn = true; // RED

         // OB mitigation check
         for(int j=i-2; j>0; j--)
            if(low[i] < high[j] && j < i - 2)
              {
               strike_dn = false;
               break;
              }

         for(int j=i-2; j>0; j--)
            if(high[i] > low[j] && j < i - 2)
              {
               strike_up = false;
               break;
              }

         // OB check
         if(strike_up)
            BufferUP[i]=close[i];
         else
            BufferUP[i]=EMPTY_VALUE;
         if(strike_dn)
            BufferDN[i]=close[i];
         else
            BufferDN[i]=EMPTY_VALUE;

         // Building OB rectangles
         if(rectanglesToggle)
           {
            if(strike_dn)
               if(!buildRectandgls("DN_OB_",i,time[i],high[i],time[0], low[i],obBullishColor))
                  Print(__FUNCTION__," Failed...");

            if(strike_up)
               if(!buildRectandgls("UP_OB_",i,time[i],high[i],time[0], low[i],obBearishColor))
                  Print(__FUNCTION__," Failed...");
           }

         // FVG
         if(fvgToggle)
           {
            bool fvg_bull = false;
            bool fvg_bear = false;

            // FVG
            if(
               high[i+1] < low[i-1]
               && close[i] > low[i-1]
               && open[i] < high[i+1]
            )
               fvg_bull = true;


            if(
               low[i+1] > high[i-1]
               && close[i] < high[i-1]
               && open[i] > low[i+1]
            )
               fvg_bear = true;

            // FVG mitigation check bullish
            for(int j=i-2; j>0; j--)
               if(low[i-1] > low[j]  && j < i - 2)
                 {
                  fvg_bull = false;
                  break;
                 }

            // FVG mitigation check bearish
            for(int j=i-2; j>0; j--)
               if(high[i-1] < high[j] && j < i - 2)
                 {
                  fvg_bear = false;
                  break;
                 }

            // Drawing FVG

            if(fvg_bull)
               if(!buildRectandgls("FVG_",i,time[i],high[i+1],time[0], low[i-1],fvgColor))
                  Print(__FUNCTION__," Failed...");

            if(fvg_bear)
               if(!buildRectandgls("FVG_",i,time[i],low[i+1],time[0], high[i-1],fvgColor))
                  Print(__FUNCTION__," Failed...");

           } // if fvg

        } // end of for loop

     }
//--- return value of prev_calculated for next call
   return rates_total;

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool buildRectandgls(string namePrefix,int i, datetime time1, double side1, datetime time0, double side2, color fillColor)
  {
   string rectName = namePrefix +IntegerToString(i);
   datetime time2 = time0+(500 * PeriodSeconds());
   ObjectCreate(0,rectName,OBJ_RECTANGLE,0,time1,side1,time2,side2);
   ObjectSetInteger(0,rectName,OBJPROP_COLOR,fillColor);
   ObjectSetInteger(0,rectName,OBJPROP_STYLE,STYLE_DASH);
   ObjectSetInteger(0,rectName,OBJPROP_WIDTH,2);
   ObjectSetInteger(0,rectName,OBJPROP_FILL,true);
   ObjectSetInteger(0,rectName,OBJPROP_BACK,true);
   ObjectSetInteger(0,rectName,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,rectName,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,rectName,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,rectName,OBJPROP_ZORDER,0);
   return true;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(!removeRectangles())
      Print(__FUNCTION__, " Failed...");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool removeRectangles()
  {
   ObjectsDeleteAll(0,"DN_OB_",-1,OBJ_RECTANGLE);
   ObjectsDeleteAll(0,"UP_OB_",-1,OBJ_RECTANGLE);
   ObjectsDeleteAll(0,"FVG_",-1,OBJ_RECTANGLE);
   return true;
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
