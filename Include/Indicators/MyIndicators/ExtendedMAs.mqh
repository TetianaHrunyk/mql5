//+------------------------------------------------------------------+
//|                                                  ExtendedMAs.mqh |
//+------------------------------------------------------------------+

#include "..\Indicator.mqh"
#include "..\Custom.mqh"

enum EXTENDED_MA {
   MASlope=0
};

//+------------------------------------------------------------------+
//| Class CiMASlope.                                                 |
//| Purpose: Class of the "MA Slope" indicator.                      |
//|          Derives from class CIndicator.                          |
//+------------------------------------------------------------------+
class CiMASlope : public CiCustom
  {


public:
                     CiMASlope(void);
                    ~CiMASlope(void);

   //--- method of creation
   bool              Create(const string symbol,const ENUM_TIMEFRAMES period,const int lookback,
                            const int ma_period, const int ma_shift,
                            const ENUM_MA_METHOD ma_method, const ENUM_APPLIED_PRICE applied);
   //--- methods of access to indicator data
   double            Main(const int index) const;
   double            Rising(const int index) const;
   double            Falling(const int index) const;
   //--- method of identifying
   virtual int       Type(void) const { return(999999); }

protected:
   //--- methods of tuning
   bool              Initialize(const string symbol,const ENUM_TIMEFRAMES period,
                                const int lookback, const int ma_period, const int ma_shift,
                                const ENUM_MA_METHOD ma_method, const ENUM_APPLIED_PRICE applied);
   bool              Initialize(const string symbol,const ENUM_TIMEFRAMES period,const int num_params,const MqlParam &params[]);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CiMASlope::CiMASlope(void)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CiMASlope::~CiMASlope(void)
  {
  }
//+------------------------------------------------------------------+
//| Create the "MASlope" indicator                                   |
//+------------------------------------------------------------------+
bool CiMASlope::Create(const string symbol,const ENUM_TIMEFRAMES period,const int lookback,
                       const int ma_period, const int ma_shift,
                       const ENUM_MA_METHOD ma_method, const ENUM_APPLIED_PRICE applied)
  {
//--- check history
   if(!SetSymbolPeriod(symbol,period))
      return(false);
//--- create;
   m_handle=iCustom(symbol,period,"MyIndicators\\MASlope", lookback, ma_period, ma_shift, ma_method, applied);
   //m_handle=iCustom(symbol,period,"MyIndicators\\lw-Slope", lookback, ma_period, ma_shift, ma_method, applied);
//--- check result
   if(m_handle==INVALID_HANDLE)
      return(false);
//--- indicator successfully created
   if(!Initialize(symbol,period,lookback,ma_period,ma_shift,ma_method,applied))
     {
      //--- initialization failed
      IndicatorRelease(m_handle);
      m_handle=INVALID_HANDLE;
      return(false);
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialize the indicator with universal parameters               |
//+------------------------------------------------------------------+
bool CiMASlope::Initialize(const string symbol,const ENUM_TIMEFRAMES period,const int num_params,const MqlParam &params[])
  {
   return(Initialize(symbol,period,(ENUM_TIMEFRAMES)params[0].integer_value,(int)params[1].integer_value,(int)params[2].integer_value,
                     (ENUM_MA_METHOD)params[3].integer_value, (ENUM_APPLIED_PRICE)params[4].integer_value));
  }

//+------------------------------------------------------------------+
//| Initialize the indicator with special parameters                 |
//+------------------------------------------------------------------+
bool CiMASlope::Initialize(const string symbol,const ENUM_TIMEFRAMES period,
                           const int lookback, const int ma_period, const int ma_shift,
                           const ENUM_MA_METHOD ma_method, const ENUM_APPLIED_PRICE applied)
  {
   if(CreateBuffers(symbol,period,2))
     {
      //--- string of status of drawing
      m_name  ="MASlope";
      m_status="("+symbol+","+PeriodDescription()+","+VolumeDescription(applied)+") H="+IntegerToString(m_handle);
      //--- save settings

      //--- create buffers
      ((CIndicatorBuffer*)At(0)).Name("RISING_LINE");
      ((CIndicatorBuffer*)At(1)).Name("FALLING_LINE");
      //--- ok
      return(true);
     }
//--- error
   return(false);
  }
  
//+------------------------------------------------------------------+
//| Access to buffer of "Moving Average Slope"                       |
//+------------------------------------------------------------------+
double CiMASlope::Main(const int index) const
  {
   CIndicatorBuffer *rising_buffer=At(0);
   CIndicatorBuffer *falling_buffer=At(1);
//--- check
   if(rising_buffer==NULL || falling_buffer==NULL)
      return(EMPTY_VALUE);
//---
   double rising_value = rising_buffer.At(index);
   double falling_value = falling_buffer.At(index);
   double final_value=1.111;
   
   if (rising_value != 0) final_value = rising_value;
   if (falling_value != 0) final_value = falling_value; 

   return(final_value);
  }
  
//+------------------------------------------------------------------+
//| Access to buffer of "Moving Average Slope"                       |
//+------------------------------------------------------------------+
double CiMASlope::Rising(const int index) const
  {
   CIndicatorBuffer *buffer=At(0);
//--- check
   if(buffer==NULL)
      return(EMPTY_VALUE);

   double val = buffer.At(index);
   return(val);
  }
  
//+------------------------------------------------------------------+
//| Access to buffer of "Moving Average Slope"                       |
//+------------------------------------------------------------------+
double CiMASlope::Falling(const int index) const
  {
   CIndicatorBuffer *buffer=At(1);
//--- check
   if(buffer==NULL)
      return(EMPTY_VALUE);

   double val = buffer.At(index);
   return(val);
  }