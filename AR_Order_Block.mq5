//+------------------------------------------------------------------+
//|                                         AR_Order_Block.mq5       |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Andrukas8"
#property link      "https://github.com/Andrukas8/AR_Order_Block"
#property version   "1.02"
#property indicator_chart_window

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

   PlotIndexSetInteger(0,PLOT_ARROW,225); // Arrow up
   PlotIndexSetInteger(1,PLOT_ARROW,226); // Arrow Down

   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,50);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,-50);

//--- setting indicator parameters
   IndicatorSetString(INDICATOR_SHORTNAME,"SquatBar");
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
//--- setting buffer arrays as timeseries
   ArraySetAsSeries(BufferUP,true);
   ArraySetAsSeries(BufferDN,true);


//---
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


// Removing rectangles
//string Name;
//for(int i = ObjectsTotal(0,0) -1 ; i >= 0; i--)
//  {
//   Name = ObjectName(0,i);
//   if(StringSubstr(Name, 0, 6) == "DN_OB_")
//      ObjectDelete(0,Name);
//   if(StringSubstr(Name, 0, 6) == "UP_OB_")
//      ObjectDelete(0,Name);
//  }


   if(rates_total<3)
      return 0;

//--- Checking and calculating the number of bars
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-5;
      ArrayInitialize(BufferUP,EMPTY_VALUE);
      ArrayInitialize(BufferDN,EMPTY_VALUE);
     }
//--- Indexing arrays as timeseries
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(time,true);

//--- Calculating the indicator

   for(int i=limit-5; i>=2 && !IsStopped(); i--)
     {

      bool strike_up=false;
      bool strike_dn=false;


      if(
         (
            low[i] < low[i+1]
            && low[i] < low[i-1]
            && high[i] < low[i-2]
         )
         ||
         (
            low[i+1] < low[i+2]
            && low[i+1] < low[i]
            && high[i+1] > low[i-1]
            && high[i] < low[i-2]
         )
      )
        {
         strike_up = true; // GREEN

        }

      if(
         (
            high[i] > high[i+1]
            && high[i] > high[i-1]
            && low[i] > high[i-2]
         )
         ||
         (
            high[i+1] > high[i+2]
            && high[i+1] > high[i]
            && low[i+1] < high[i-1]
            && low[i] > high[i-2]
         )

      )
        {
         strike_dn = true; // RED
        }


      for(int j=i-2;j>0;j--)
        {
         if(low[i] < high[j])
           {
            strike_dn = false;
            break;
           }
        }

      for(int j=i-2;j>0;j--)
        {
         if(high[i] > low[j])
           {
            strike_up = false;
            break;
           }
        }

      if(strike_up)
        {
         BufferUP[i]=close[i];
         //ObjectCreate(0,"UP_OB_"+IntegerToString(i),OBJ_RECTANGLE,0,time[i],high[i],time[0],low[i]);
        }
      else
         BufferUP[i]=EMPTY_VALUE;
      if(strike_dn)
        {
         BufferDN[i]=close[i];
         //ObjectCreate(0,"DN_OB_"+IntegerToString(i),OBJ_RECTANGLE,0,time[i],high[i],time[0],low[i]);
        }
      else
         BufferDN[i]=EMPTY_VALUE;
     }

//--- return value of prev_calculated for next call
   return(rates_total);

  }


//+------------------------------------------------------------------+
