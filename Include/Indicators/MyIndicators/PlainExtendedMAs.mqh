//+------------------------------------------------------------------+
//|                                                  ExtendedMAs.mqh |
//+------------------------------------------------------------------+


enum EXTENDED_MA
  {
   MASlope=0
  };

//+------------------------------------------------------------------+
//| Class CiPMASlope.                                                 |
//| Purpose: Class of the "MA Slope" indicator.                      |
//|          Derives from class CIndicator.                          |
//+------------------------------------------------------------------+
class CiPMASlope
  {


public:
                     CiPMASlope(void);
                    ~CiPMASlope(void);

   //--- method of creation
   bool              Create(string symbol, ENUM_TIMEFRAMES period, int lookback,
                            int ma_period,  int ma_shift,
                            ENUM_MA_METHOD ma_method,  ENUM_APPLIED_PRICE applied);
   //--- methods of access to indicator data
   double            Main(int index) ;
   double            Rising(int index) ;
   double            Falling(int index) ;

protected:
   //--- methods of tuning
   int               m_handle;
   double            m_buff_rising[];
   double            m_buff_falling[];
   bool              Refresh(int bars=100) ;
   bool              Initialize(string symbol, ENUM_TIMEFRAMES period,
                                int lookback,  int ma_period,  int ma_shift,
                                ENUM_MA_METHOD ma_method,  ENUM_APPLIED_PRICE applied);
   bool              Initialize(string symbol, ENUM_TIMEFRAMES period, int num_params, MqlParam &params[]);
  };
//+------------------------------------------------------------------+
//| ructor                                                      |
//+------------------------------------------------------------------+
CiPMASlope::CiPMASlope(void)
  {
   ArraySetAsSeries(m_buff_rising, true);
   ArraySetAsSeries(m_buff_falling, true);
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CiPMASlope::~CiPMASlope(void)
  {
  }
//+------------------------------------------------------------------+
//| Create the "MASlope" indicator                                   |
//+------------------------------------------------------------------+
bool CiPMASlope::Create(string symbol, ENUM_TIMEFRAMES period, int lookback,
                       int ma_period,  int ma_shift,
                       ENUM_MA_METHOD ma_method,  ENUM_APPLIED_PRICE applied)
  {
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
      m_handle=INVALID_HANDLE;
      return(false);
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialize the indicator with universal parameters               |
//+------------------------------------------------------------------+
bool CiPMASlope::Initialize(string symbol, ENUM_TIMEFRAMES period, int num_params, MqlParam &params[])
  {
   return(Initialize(symbol,period,(ENUM_TIMEFRAMES)params[0].integer_value,(int)params[1].integer_value,(int)params[2].integer_value,
                     (ENUM_MA_METHOD)params[3].integer_value, (ENUM_APPLIED_PRICE)params[4].integer_value));
  }

//+------------------------------------------------------------------+
//| Initialize the indicator with special parameters                 |
//+------------------------------------------------------------------+
bool CiPMASlope::Initialize(string symbol, ENUM_TIMEFRAMES period,
                           int lookback,  int ma_period,  int ma_shift,
                           ENUM_MA_METHOD ma_method,  ENUM_APPLIED_PRICE applied)
  {
   if(!Refresh())
      return(false);
   return(true);
  }

//+------------------------------------------------------------------+
//| Refresh                                                          |
//+------------------------------------------------------------------+
bool CiPMASlope::Refresh(int bars=100)
  {
   bool res = true;

   if(!CopyBuffer(m_handle, 0, 0, bars, m_buff_rising))
     {
      res = false;
     }
   if(!CopyBuffer(m_handle, 1, 0, bars, m_buff_falling))
     {
      res = false;
     }
   return(res);
  }

//+------------------------------------------------------------------+
//| Access to buffer of "Moving Average Slope"                       |
//+------------------------------------------------------------------+
double CiPMASlope::Main(int index)
  {

   double rising_value = Rising(index+10);
   double falling_value = Falling(index+10);
   double final_value=1.111;

   if(rising_value != 0)
      final_value = rising_value;
   if(falling_value != 0)
      final_value = falling_value;

   return(final_value);
  }

//+------------------------------------------------------------------+
//| Access to buffer of "Moving Average Slope"                       |
//+------------------------------------------------------------------+
double CiPMASlope::Rising(int index)
  {
   Refresh(index+1);
   return(m_buff_rising[index]);
  }

//+------------------------------------------------------------------+
//| Access to buffer of "Moving Average Slope"                       |
//+------------------------------------------------------------------+
double CiPMASlope::Falling(int index)
  {
   Refresh(index+1);
   return(m_buff_falling[index]);
  }
//+------------------------------------------------------------------+
