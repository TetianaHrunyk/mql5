//+------------------------------------------------------------------+
//|                                                        FATRs.mqh |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Class CiFATR.                                                    |
//| Purpose: Class of the "Filtered ATR" indicator.                  |
//|          Derives from class CIndicator.                          |
//+------------------------------------------------------------------+
class CiFATR
  {
  
  
public:
                     CiFATR(void);
                    ~CiFATR(void);

   //--- method of creation
   bool              Create(const string symbol,const ENUM_TIMEFRAMES period,const int atr_period,const double filter);
   //--- methods of access to indicator data
   double            Main(int index) ;
   double            Spikes(int index) ;

protected:
   //--- methods of tuning
   int               m_handle;
   double            m_buff_main[];
   double            m_buff_spikes[];
   bool              Refresh(int bars=100) ;
   bool              Initialize(string symbol,ENUM_TIMEFRAMES period,int atr_period,double filter);
   bool              Initialize(string symbol, ENUM_TIMEFRAMES period, int num_params, MqlParam &params[]);
  };
//+------------------------------------------------------------------+
//| ructor                                                      |
//+------------------------------------------------------------------+
CiFATR::CiFATR(void)
  {
   ArraySetAsSeries(m_buff_main, true);
   ArraySetAsSeries(m_buff_spikes, true);
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CiFATR::~CiFATR(void)
  {
  }
//+------------------------------------------------------------------+
//| Create the "FATR" indicator                                   |
//+------------------------------------------------------------------+
bool CiFATR::Create(const string symbol,const ENUM_TIMEFRAMES period,const int atr_period,const double filter)
  {
//--- create;
   m_handle=iCustom(symbol,period,"MyIndicators\\FilteredATR", atr_period, filter);

//--- check result
   if(m_handle==INVALID_HANDLE)
      return(false);
//--- indicator successfully created
   if(!Initialize(symbol,period,atr_period,filter))
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
bool CiFATR::Initialize(string symbol, ENUM_TIMEFRAMES period, int num_params, MqlParam &params[])
  {
   return(Initialize(symbol,period,(int)params[0].integer_value, (double)params[1].integer_value));
  }

//+------------------------------------------------------------------+
//| Initialize the indicator with special parameters                 |
//+------------------------------------------------------------------+
bool CiFATR::Initialize(string symbol,ENUM_TIMEFRAMES period,int atr_period,double filter)
  {
   if(!Refresh())
      return(false);
   return(true);
  }

//+------------------------------------------------------------------+
//| Refresh                                                          |
//+------------------------------------------------------------------+
bool CiFATR::Refresh(int bars=100)
  {
   bool res = true;

   if(!CopyBuffer(m_handle, 0, 0, bars, m_buff_main))
     {
      res = false;
     }
   if(!CopyBuffer(m_handle, 1, 0, bars, m_buff_spikes))
     {
      res = false;
     }
   return(res);
  }

//+------------------------------------------------------------------+
//| Access to main buffer                                            |
//+------------------------------------------------------------------+
double CiFATR::Main(int index)
  {
   Refresh(index+1);
   return(m_buff_main[index]);
  }

//+------------------------------------------------------------------+
//| Access to spikes buffer                                          |
//+------------------------------------------------------------------+
double CiFATR::Spikes(int index)
  {
   Refresh(index+1);
   return(m_buff_spikes[index]);
  }

//+------------------------------------------------------------------+
