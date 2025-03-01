//+-------------------------------------------------------------+
//|                                    Signal_Detector_Main.mq4 |
//|                                              Copyright 2024 |
//|                                                             |
//+-------------------------------------------------------------+
#property copyright "Copyright 2024"
#property version   "1.00"
#property description "Signal Detector - Main"
#property strict

#define minute1 (60)

//#include "Mixed_Indicators.mqh"   // Include your indicators
//#include <Indicators/Indicator.mqh>
#include <MovingAverages.mqh>

//---- indicator settings
#property indicator_chart_window

//#property indicator_separate_window
#property indicator_buffers 5
#property indicator_color1  clrBlue
#property indicator_color2  clrRed
#property indicator_color3  clrLime
#property indicator_color4  clrBlue
#property indicator_color5  clrRed

input bool InpPopup_Alert= false;
//---- input parameters
input string InpText0 = "-- Alligator -- ";  // Group
input int InpJawsPeriod=13; // Jaws Period
input int InpJawsShift=8;   // Jaws Shift
input int InpTeethPeriod=8; // Teeth Period
input int InpTeethShift=5;  // Teeth Shift
input int InpLipsPeriod=5;  // Lips Period
input int InpLipsShift=3;   // Lips Shift
//input int InpMaPeriod=3;    //averaging period
input ENUM_MA_METHOD InpMaMethod=MODE_SMMA; // method of averaging of the Alligator lines
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_MEDIAN;// type of price used for calculation of Alligator

color button_bg_color = clrLightCyan;    
color button_txt_color = clrNavy;   
int button_height = 18; 
bool symbol_button_show = true;
ENUM_BASE_CORNER symbol_corner = CORNER_LEFT_UPPER;
string button_font_name = "Lucida Console";

int button_font_size = 08;                
color button_border_color = clrNONE;          
bool button_back = false;             
bool button_state = false;             
bool button_selection = false;            
bool button_selected = false;            
bool button_hidden = true;              
long button_zorder = 0;                 
int button_first_y_distance = 20; 

int space_no = 4;
int space_sym = 12;
int space_signal = 8;

string obj_prefix = "SDM_";

//---- indicator buffers
double ExtBlueBuffer[];
double ExtRedBuffer[];
double ExtLimeBuffer[];

double ExtMapBuffer1[];
double ExtMapBuffer2[];

string multi_currency0[28] = { "XAUUSD","AUDCAD","AUDCHF","AUDJPY","AUDNZD","AUDUSD","CADCHF","CADJPY",
                              "CHFJPY","EURAUD","EURCAD","EURGBP","EURJPY","EURNZD","EURUSD",
                              "GBPAUD","GBPCAD","GBPCHF","GBPJPY","GBPNZD","GBPUSD","NZDCAD",
                              "NZDCHF","NZDJPY","NZDUSD","USDCAD","USDCHF","USDJPY"};

string multi_currency[28];
datetime multi_currency_time[28];
int timebar = 3;
int period_no;
int nShift;  

string sym10_name[28];
string sym10_signal[28];
string sym10_signal_type[28];
datetime sym10_time[28];

int button_width;
int symbol_x_distance = 10;

int timeframe_shift;
datetime default_time; 

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(void)
{
   datetime Expiry=D'2025.12.30';
   if(TimeLocal()>Expiry)
   {
      Alert(WindowExpertName()+" Testing Duration Expired");
      return(INIT_FAILED);
   }
   
   int account_no=0;
   if( AccountNumber() != account_no && account_no > 0)
   {
       Print("Invalid Account ");
       Alert("Invalid Account ");
       
       return(INIT_FAILED);
   }

   string short_name="Signal Detector"; 
   IndicatorShortName(short_name); 
   
   IndicatorBuffers(8);
   IndicatorDigits(Digits);

//---- 3 indicator buffers mapping
   SetIndexBuffer(0,ExtBlueBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtRedBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtLimeBuffer,INDICATOR_DATA);
   
//---- drawing settings
   SetIndexStyle(0,DRAW_LINE);
   SetIndexStyle(1,DRAW_LINE);
   SetIndexStyle(2,DRAW_LINE);
   
//---- index labels
   SetIndexLabel(0,"J");
   SetIndexLabel(1,"T");
   SetIndexLabel(2,"L");
   
   SetIndexStyle(3, DRAW_ARROW, 0, 1);
   SetIndexArrow(3, 233);
   SetIndexBuffer(3, ExtMapBuffer1);
//----
   SetIndexStyle(4, DRAW_ARROW, 0, 1);
   SetIndexArrow(4, 234);
   SetIndexBuffer(4, ExtMapBuffer2);
    
   SetIndexLabel(3,"Signal UP");
   SetIndexLabel(4,"Signal DW");
    
   switch(Period())
   {
      case     1: nShift = 1;   break;    
      case     5: nShift = 3;   break;
      case    15: nShift = 5;   break;
      case    30: nShift = 10;  break;
      case    60: nShift = 15;  break;
      case   240: nShift = 20;  break;
      case  1440: nShift = 80;  break;
      case 10080: nShift = 100; break;
      case 43200: nShift = 200; break;              
   }
   
   switch(Period())
   {
      case     1: period_no = PERIOD_M1;  break;    
      case     5: period_no = PERIOD_M5;  break;
      case    15: period_no = PERIOD_M15; break;
      case    30: period_no = PERIOD_M30; break;
      case    60: period_no = PERIOD_H1;  break;
      case   240: period_no = PERIOD_H4;  break;
      case  1440: period_no = PERIOD_D1;  break;
      case 10080: period_no = PERIOD_W1;  break;
      case 43200: period_no = PERIOD_MN1; break;              
   }
   default_time = iTime(Symbol(),period_no,0) - (minute1*period_no*timebar);
   
   GetPrefixSuffix();
   ArrayInitialize(sym10_time,default_time);
   //--- button width value set:
   if(button_height<=12)
   {
      button_width=190;
   } 
   else 
   {
      button_width=260;
   }
   
   //timeframe_shift
   ClearSymArray();
   Proceed_BarTime(0);
   
   return(INIT_SUCCEEDED);
}

  
void obj_clear() 
{
  string name;
  int obj_total = ObjectsTotal();
  for (int i=obj_total-1; i>=0; i--)
  {
    name = ObjectName(i);
    if (StringFind(name, obj_prefix) >= 0) ObjectDelete(name);
  }
}

void ClearSymArray()
{
   for(int x = 0; x < 28; x++)
   {
      sym10_name[x] = ""; 
      sym10_signal[x] = "";  
      sym10_signal_type[x] = "";  
      sym10_time[x] = default_time; 
   }
}

void Title_List()
{
   int y_distance_0 = (button_first_y_distance+(button_height*0));   
   string obj_name = obj_prefix+"_name";
   string obj_text0 = PadString("NO.", space_no)+"|";
   obj_text0 += PadString(" SYMBOL", space_sym)+"|";
   obj_text0 += PadString(" BUY", space_signal)+"|";
   obj_text0 += PadString(" SELL", space_signal);
   obj_button_create(obj_name, symbol_x_distance, y_distance_0, obj_text0);
}

void Gold_List()
{
   printf("Proceeding Gold");
   int minute_gap = (minute1*period_no*timebar);
   datetime expired_time = sym10_time[0] + minute_gap;
   
   double sym_jaw_1 = iAlligator(multi_currency[0],period_no,InpJawsPeriod,InpJawsShift,InpTeethPeriod,InpTeethShift,InpLipsPeriod,InpLipsShift,InpMaMethod,InpAppliedPrice,MODE_GATORJAW,1);
   double sym_teeth_1 =iAlligator(multi_currency[0],period_no,InpJawsPeriod,InpJawsShift,InpTeethPeriod,InpTeethShift,InpLipsPeriod,InpLipsShift,InpMaMethod,InpAppliedPrice,MODE_GATORTEETH,1);
   double sym_lips_1 =iAlligator(multi_currency[0],period_no,InpJawsPeriod,InpJawsShift,InpTeethPeriod,InpTeethShift,InpLipsPeriod,InpLipsShift,InpMaMethod,InpAppliedPrice,MODE_GATORLIPS,1);
      
   double sym_jaw_2 = iAlligator(multi_currency[0],period_no,InpJawsPeriod,InpJawsShift,InpTeethPeriod,InpTeethShift,InpLipsPeriod,InpLipsShift,InpMaMethod,InpAppliedPrice,MODE_GATORJAW,2);
   double sym_teeth_2 =iAlligator(multi_currency[0],period_no,InpJawsPeriod,InpJawsShift,InpTeethPeriod,InpTeethShift,InpLipsPeriod,InpLipsShift,InpMaMethod,InpAppliedPrice,MODE_GATORTEETH,2);
   double sym_lips_2 =iAlligator(multi_currency[0],period_no,InpJawsPeriod,InpJawsShift,InpTeethPeriod,InpTeethShift,InpLipsPeriod,InpLipsShift,InpMaMethod,InpAppliedPrice,MODE_GATORLIPS,2);
   
   // ----------------------  STRONG  ------------------------------
   if(sym_jaw_1 >= sym_teeth_1 && sym_jaw_1 >= sym_lips_1 && sym_teeth_1 >= sym_lips_1 // Jaws > Teeth > Lips
      && ( (sym_jaw_2 <= sym_teeth_2) || (sym_jaw_2 <= sym_lips_2) || (sym_teeth_2 <= sym_lips_2) ) )
   {
      sym10_name[0] = multi_currency[0];
      sym10_signal[0] = "Strong";  
      sym10_signal_type[0] = "Sell"; 
      sym10_time[0] = iTime(multi_currency[0],period_no,0);
      printf(sym10_name[0]+" - "+sym10_signal[0]+" "+sym10_signal_type[0]+" - "+TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
      if(InpPopup_Alert == true)
      {
         Alert(sym10_name[0]+" - "+sym10_signal[0]+" "+sym10_signal_type[0]+" - "+TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
      }
   }
   else if(sym_jaw_1 <= sym_teeth_1 && sym_jaw_1 <= sym_lips_1 && sym_teeth_1 <= sym_lips_1 // Jaws < Teeth < Lips
      && ( (sym_jaw_2 >= sym_teeth_2) || (sym_jaw_2 >= sym_lips_2) || (sym_teeth_2 >= sym_lips_2) ) )
   {
      sym10_name[0] = multi_currency[0];
      sym10_signal[0] = "Strong";  
      sym10_signal_type[0] = "Buy";    
      sym10_time[0] = iTime(multi_currency[0],period_no,0);
      printf(sym10_name[0]+" - "+sym10_signal[0]+" "+sym10_signal_type[0]+" - "+TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
      if(InpPopup_Alert == true)
      {
         Alert(sym10_name[0]+" - "+sym10_signal[0]+" "+sym10_signal_type[0]+" - "+TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
      }
   } // ----------------------  LOW  ------------------------------
   else if( (sym_jaw_1 < sym_teeth_1 && sym_jaw_1 < sym_lips_1 && sym_lips_1 < sym_teeth_1)  // Jaws < Teeth < Lips
      && (sym_jaw_2 <= sym_teeth_2 && sym_jaw_2 <= sym_lips_2 && sym_lips_2 >= sym_teeth_2) ) 
   {
      sym10_name[0] = multi_currency[0];
      sym10_signal[0] = "Low";  
      sym10_signal_type[0] = "Sell"; 
      sym10_time[0] = iTime(multi_currency[0],period_no,0);
      printf(sym10_name[0]+" - "+sym10_signal[0]+" "+sym10_signal_type[0]+" - "+TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
      if(InpPopup_Alert == true)
      {
         Alert(sym10_name[0]+" - "+sym10_signal[0]+" "+sym10_signal_type[0]+" - "+TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
      }
   }
   else if( (sym_jaw_1 > sym_teeth_1 && sym_jaw_1 > sym_lips_1 && sym_lips_1 < sym_teeth_1) // Jaws < Teeth < Lips
      && (sym_jaw_2 >= sym_teeth_2 && sym_jaw_2 >= sym_lips_2 && sym_lips_2 <= sym_teeth_2) )
   {
      sym10_name[0] = multi_currency[0];
      sym10_signal[0] = "Low";  
      sym10_signal_type[0] = "Buy";    
      sym10_time[0] = iTime(multi_currency[0],period_no,0);
      printf(sym10_name[0]+" - "+sym10_signal[0]+" "+sym10_signal_type[0]+" - "+TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
      
      if(InpPopup_Alert == true)
      {
         Alert(sym10_name[0]+" - "+sym10_signal[0]+" "+sym10_signal_type[0]+" - "+TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
      }
   }
   else
   {
      if(TimeCurrent() >= expired_time)
      {
         sym10_signal[0] = "";   
         sym10_signal_type[0] = "";
      }
   }
   
   int button_gap = 1;   
   string obj_name = obj_prefix+"_"+multi_currency[0];
   int y_distance = (button_first_y_distance+(button_height*button_gap));
         
   string obj_text = PadString("1.", space_no)+"|";
   obj_text += PadString(" "+multi_currency[0], space_sym)+"|";  
   
   // buy 
   if(sym10_signal_type[0] == "Buy")
   {
      obj_text += PadString(sym10_signal[0], space_signal)+"|"; 
   }else
   {
      obj_text += PadString("", space_signal)+"|";  
   } 
   // sell 
   if(sym10_signal_type[0] == "Sell")
   {
      obj_text += PadString(sym10_signal[0], space_signal); 
   }else
   {
      obj_text += PadString("", space_signal);  
   }
   
   obj_button_create(obj_name, symbol_x_distance, y_distance, obj_text);
}

void Symbol_List()
{
   int minute_gap = (minute1*period_no*timebar);
   string symbol_namelist = "0";
   int cnt_0 = 1;
   for(int x = 1; x < 28; x++)
   {
      datetime signal_time = sym10_time[x] + minute_gap;
      if(TimeCurrent() < signal_time)
      {
         sym10_name[cnt_0] = sym10_name[x]; 
         sym10_signal[cnt_0] = sym10_signal[x];  
         sym10_signal_type[cnt_0] = sym10_signal_type[x];  
         sym10_time[cnt_0] = sym10_time[x]; 
         symbol_namelist += (","+sym10_name[cnt_0]);
         
         cnt_0++; 
      }  
   }
   int reset_cnt = cnt_0;
   for(int x = reset_cnt; x < 28; x++)
   {
      sym10_name[x] = ""; 
      sym10_signal[x] = "";  
      sym10_signal_type[x] = "";  
      sym10_time[x] = default_time; 
      reset_cnt++; 
   }
   
   for(int x = 1; x < 28; x++)
   {
      int sym_digits = (int)SymbolInfoInteger(multi_currency[x], SYMBOL_DIGITS);
      double sym_jaw_1 = iAlligator(multi_currency[x],period_no,InpJawsPeriod,InpJawsShift,InpTeethPeriod,InpTeethShift,InpLipsPeriod,InpLipsShift,InpMaMethod,InpAppliedPrice,MODE_GATORJAW,1);
      double sym_teeth_1 =iAlligator(multi_currency[x],period_no,InpJawsPeriod,InpJawsShift,InpTeethPeriod,InpTeethShift,InpLipsPeriod,InpLipsShift,InpMaMethod,InpAppliedPrice,MODE_GATORTEETH,1);
      double sym_lips_1 =iAlligator(multi_currency[x],period_no,InpJawsPeriod,InpJawsShift,InpTeethPeriod,InpTeethShift,InpLipsPeriod,InpLipsShift,InpMaMethod,InpAppliedPrice,MODE_GATORLIPS,1);
      
      double sym_jaw_2 = iAlligator(multi_currency[x],period_no,InpJawsPeriod,InpJawsShift,InpTeethPeriod,InpTeethShift,InpLipsPeriod,InpLipsShift,InpMaMethod,InpAppliedPrice,MODE_GATORJAW,2);
      double sym_teeth_2 =iAlligator(multi_currency[x],period_no,InpJawsPeriod,InpJawsShift,InpTeethPeriod,InpTeethShift,InpLipsPeriod,InpLipsShift,InpMaMethod,InpAppliedPrice,MODE_GATORTEETH,2);
      double sym_lips_2 =iAlligator(multi_currency[x],period_no,InpJawsPeriod,InpJawsShift,InpTeethPeriod,InpTeethShift,InpLipsPeriod,InpLipsShift,InpMaMethod,InpAppliedPrice,MODE_GATORLIPS,2);
      
      if(sym_jaw_1 >= sym_teeth_1 && sym_jaw_1 >= sym_lips_1 && sym_teeth_1 >= sym_lips_1 // Jaws > Teeth > Lips
      && ( (sym_jaw_2 <= sym_teeth_2) || (sym_jaw_2 <= sym_lips_2) || (sym_teeth_2 <= sym_lips_2) ) )
      {
         if( StringFind(symbol_namelist, multi_currency[x],0) < 0 && cnt_0 < 28)
         {
            sym10_name[cnt_0] = multi_currency[x]; 
            sym10_signal[cnt_0] = "Strong";  
            sym10_signal_type[cnt_0] = "Sell"; 
            sym10_time[cnt_0] = iTime(multi_currency[x],period_no,0); 
            printf(sym10_name[cnt_0]+" - "+sym10_signal[cnt_0]+" "+sym10_signal_type[cnt_0]+" - "+TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
            if(InpPopup_Alert == true)
            {
               Alert(sym10_name[cnt_0]+" - "+sym10_signal[cnt_0]+" "+sym10_signal_type[cnt_0]+" - "+TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
            }
            cnt_0++;
         }
      }
      else if(sym_jaw_1 <= sym_teeth_1 && sym_jaw_1 <= sym_lips_1 && sym_teeth_1 <= sym_lips_1 // Jaws < Teeth < Lips
         && ( (sym_jaw_2 >= sym_teeth_2) || (sym_jaw_2 >= sym_lips_2) || (sym_teeth_2 >= sym_lips_2) ) )
      {
         if( StringFind(symbol_namelist, multi_currency[x],0) < 0 && cnt_0 < 28 )
         {
            sym10_name[cnt_0] = multi_currency[x]; 
            sym10_signal[cnt_0] = "Strong";  
            sym10_signal_type[cnt_0] = "Buy"; 
            sym10_time[cnt_0] = iTime(multi_currency[x],period_no,0); 
            printf(sym10_name[cnt_0]+" - "+sym10_signal[cnt_0]+" "+sym10_signal_type[cnt_0]+" - "+TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
            if(InpPopup_Alert == true)
            {
               Alert(sym10_name[cnt_0]+" - "+sym10_signal[cnt_0]+" "+sym10_signal_type[cnt_0]+" - "+TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
               
            }
            cnt_0++;
         }
      }
      // ----------------------  LOW  ------------------------------
      else if( (sym_jaw_1 < sym_teeth_1 && sym_jaw_1 < sym_lips_1 && sym_lips_1 < sym_teeth_1)  
         && (sym_jaw_2 <= sym_teeth_2 && sym_jaw_2 <= sym_lips_2 && sym_lips_2 >= sym_teeth_2) ) // Jaws < Teeth < Lips
      {
         if( StringFind(symbol_namelist, multi_currency[x],0) < 0 && cnt_0 < 28 )
         {
            sym10_name[cnt_0] = multi_currency[x]; 
            sym10_signal[cnt_0] = "Low";  
            sym10_signal_type[cnt_0] = "Sell"; 
            sym10_time[cnt_0] = iTime(multi_currency[x],period_no,0);
            printf(sym10_name[cnt_0]+" - "+sym10_signal[cnt_0]+" "+sym10_signal_type[cnt_0]+" - "+TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
            if(InpPopup_Alert == true)
            {
               Alert(sym10_name[cnt_0]+" - "+sym10_signal[cnt_0]+" "+sym10_signal_type[cnt_0]+" - "+TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
            }
         }
      }
      else if( (sym_jaw_1 > sym_teeth_1 && sym_jaw_1 > sym_lips_1 && sym_lips_1 > sym_teeth_1) // Jaws < Teeth < Lips
         && (sym_jaw_2 >= sym_teeth_2 && sym_jaw_2 >= sym_lips_2 && sym_lips_2 <= sym_teeth_2) )
      {
         if( StringFind(symbol_namelist, multi_currency[x],0) < 0 && cnt_0 < 28 )
         {
            sym10_name[cnt_0] = multi_currency[x];
            sym10_signal[cnt_0] = "Low";  
            sym10_signal_type[cnt_0] = "Buy";    
            sym10_time[cnt_0] = iTime(multi_currency[x],period_no,0);
            printf(sym10_name[cnt_0]+" - "+sym10_signal[cnt_0]+" "+sym10_signal_type[cnt_0]+" - "+TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
            if(InpPopup_Alert == true)
            {
               Alert(sym10_name[cnt_0]+" - "+sym10_signal[cnt_0]+" "+sym10_signal_type[cnt_0]+" - "+TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
            }
         }
      }
   }
   
   for(int x = 1; x < 10; x++)
   {
      if(StringLen(sym10_name[x]) > 0)
      {
         int button_gap = x+1;
         string obj_name = obj_prefix+"_"+sym10_name[x]; 
         int y_distance = (button_first_y_distance+(button_height*button_gap));
         
         datetime expired_time = sym10_time[x] + minute_gap;
                  
         string obj_text1 = PadString(button_gap+".", 4)+"|";
         obj_text1 += PadString(" "+sym10_name[x], 12)+"|"; 
            
         // buy 
         if(sym10_signal_type[x] == "Buy")
         {
            obj_text1 += PadString(sym10_signal[x], 8)+"|"; 
         }else
         {
            obj_text1 += PadString("", 8)+"|";  
         } 
         // sell 
         if(sym10_signal_type[x] == "Sell")
         {
            obj_text1 += PadString(sym10_signal[x], 8); 
         }else
         {
            obj_text1 += PadString("", 8);  
         }
            
         //display_text += obj_text1+" len:"+StringLen(obj_text1)+"|"+period_no+"|Time:"+TimeToString(sym10_time[0],TIME_DATE|TIME_MINUTES)+", Expired: "+TimeToString(expired_time,TIME_DATE|TIME_MINUTES)+" \n";
         obj_button_create(obj_name, symbol_x_distance, y_distance, obj_text1);
      }
   }
}

void Proceed_BarTime(int shift)
{
   if(timeframe_shift != iBars(Symbol(),0))
   {
      obj_clear(); 
      Title_List();
      Gold_List();
      Symbol_List();
      
      timeframe_shift = iBars(Symbol(),0);
   }
}

void OnDeinit(const int reason)
{
   //--- objects delete function:
   int obj_total=ObjectsTotal(); 
   //PrintFormat("Total %d objects",obj_total); 
   for(int i=obj_total-1;i>=0;i--) 
   { 
      string name=ObjectName(i); 
      int pos = StringFind(name,obj_prefix,0);
      if (pos > -1)
      {
         //PrintFormat("object %d: %s",i,name); 
         ObjectDelete(name); 
      }
   } 
   Comment("");
}
  
void GetPrefixSuffix()
{ 
   int      total=0; 
   string   symbolName="";
   string   symname_arr = "";
   
   total=SymbolsTotal(false);
   for(int n=0; n < 28; n++)
   {
      symname_arr = multi_currency0[n];
      for(int i=0;i<total;i++)
      {
         //--- Symbol name on the server
         symbolName=SymbolName(i,false);
         int pos = StringFind(symbolName,symname_arr,0);
         if (pos > -1)
         {
            multi_currency[n] = symbolName;
            if(SymbolInfoInteger(symbolName, SYMBOL_VISIBLE) == false)
            {  SymbolSelect(symbolName, true); }
            break;
         } 
      }
   }
}

void obj_button_create(string symbol_name, int x_distance, int y_distance, string symbol_text)
{
   //--- set button on chart:
   ObjectCreate(0,symbol_name,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,symbol_name,OBJPROP_XDISTANCE,x_distance);
   ObjectSetInteger(0,symbol_name,OBJPROP_YDISTANCE,y_distance);
   ObjectSetInteger(0,symbol_name,OBJPROP_XSIZE,button_width);
   ObjectSetInteger(0,symbol_name,OBJPROP_YSIZE,button_height);
   ObjectSetInteger(0,symbol_name,OBJPROP_CORNER,symbol_corner);
   ObjectSetString(0,symbol_name,OBJPROP_TEXT,symbol_text);
   ObjectSetString(0,symbol_name,OBJPROP_FONT,button_font_name);
   ObjectSetInteger(0,symbol_name,OBJPROP_FONTSIZE,button_font_size);
   ObjectSetInteger(0,symbol_name,OBJPROP_COLOR,button_txt_color);
   ObjectSetInteger(0,symbol_name,OBJPROP_BORDER_COLOR,button_border_color);
   ObjectSetInteger(0,symbol_name,OBJPROP_BACK,button_back);
   ObjectSetInteger(0,symbol_name,OBJPROP_SELECTABLE,button_selection);
   ObjectSetInteger(0,symbol_name,OBJPROP_SELECTED,button_selected);
   ObjectSetInteger(0,symbol_name,OBJPROP_HIDDEN,button_hidden);
   ObjectSetInteger(0,symbol_name,OBJPROP_BGCOLOR,button_bg_color);
   ObjectSetInteger(0,symbol_name,OBJPROP_ZORDER,button_zorder);
   ObjectSetInteger(0,symbol_name,OBJPROP_STATE,button_state);
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
   ChartSetInteger(CHART_MODE,CHART_FOREGROUND,false);
   
   //int limit=rates_total-prev_calculated;
   int limit=rates_total-1;
   string text = "rates_total: "+rates_total+" | prev_calculated: "+prev_calculated+" | limit: "+limit+"\n";
   for(int i=0;  i<limit;i++)
   {
      ExtBlueBuffer[i]=iAlligator(NULL,NULL,InpJawsPeriod,InpJawsShift,InpTeethPeriod,InpTeethShift,InpLipsPeriod,InpLipsShift,
                                 InpMaMethod,InpAppliedPrice,MODE_GATORJAW,i);
      ExtRedBuffer[i]=iAlligator(NULL,NULL,InpJawsPeriod,InpJawsShift,InpTeethPeriod,InpTeethShift,InpLipsPeriod,InpLipsShift,
                                 InpMaMethod,InpAppliedPrice,MODE_GATORTEETH,i );
      ExtLimeBuffer[i]=iAlligator(NULL,NULL,InpJawsPeriod,InpJawsShift,InpTeethPeriod,InpTeethShift,InpLipsPeriod,InpLipsShift,
                                  InpMaMethod,InpAppliedPrice,MODE_GATORLIPS,i);
   }
   
   for(int i=0;  i<limit-2;i++)
   {
      double Jaw_0 = ExtBlueBuffer[i+1]; 
      double Teeth_0 = ExtRedBuffer[i+1];
      double Lips_0 = ExtLimeBuffer[i+1];
      
      double Jaw_1 = ExtBlueBuffer[i+2]; 
      double Teeth_1 = ExtRedBuffer[i+2];
      double Lips_1 = ExtLimeBuffer[i+2];
      //      
      // ---------------------- STRONG -------------------
      if(Jaw_0 >= Teeth_0 && Jaw_0 >= Lips_0 && Teeth_0 >= Lips_0 // Jaws > Teeth > Lips
      && ( (Jaw_1 <= Teeth_1) || (Jaw_1 <= Lips_1) || (Teeth_1 <= Lips_1) ) )
      {
         ExtMapBuffer2[i+1] = High[i+1] + nShift*Point;
      }
      
      if(Jaw_0 <= Teeth_0 && Jaw_0 <= Lips_0 && Teeth_0 <= Lips_0 // Jaws < Teeth < Lips
      && ( (Jaw_1 >= Teeth_1) || (Jaw_1 >= Lips_1) || (Teeth_1 >= Lips_1) ) )
      {
         ExtMapBuffer1[i+1] = Low[i+1] - nShift*Point;
      }
      
      // ----------------------  LOW  -------------------
      if( (Jaw_0 <= Teeth_0 && Jaw_0 <= Lips_0 && Teeth_0 > Lips_0)  
      && (Jaw_1 <= Teeth_1 && Jaw_1 <= Lips_1 && Teeth_1 <= Lips_1) )// Jaws < Teeth < Lips
      {
         ExtMapBuffer2[i+1] = High[i+1] + nShift*Point;
      }
      
      if( (Jaw_0 >= Teeth_0 && Jaw_0 >= Lips_0 && Teeth_0 < Lips_0)  
      && (Jaw_1 >= Teeth_1 && Jaw_1 >= Lips_1 && Teeth_1 >= Lips_1) )// Jaws < Teeth < Lips
      {
         ExtMapBuffer1[i+1] = Low[i+1] - nShift*Point;
      }
   }
   
   Proceed_BarTime(0);
   
   //Comment(display_text+text+"\nBlue: "+ArraySize(ExtBlueBuffer)+" - Red: "+ArraySize(ExtRedBuffer)+" - Lime: "+ArraySize(ExtLimeBuffer) );

//---- done
   return(rates_total);
}

string proceed_signal_text(string text, int target_len)
{
   string local_text = text;
   int strlen = StringLen(local_text);
   
   for(int x=strlen; x < target_len; x++ )
   {
      local_text+= " ";
   }
   
   return(local_text);
}

string PadString(string text, int target_len)
{
   string local_text = text;
   int strlen = StringLen(local_text);
   
   for(int x=strlen; x < target_len; x++ )
   {
      local_text+= " ";
   }
   return(local_text);
}

