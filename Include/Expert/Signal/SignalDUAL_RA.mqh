//+------------------------------------------------------------------+
//|                                                     SignalRA.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include             <Expert\ExpertSignal.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals of indicator 'Dual Regression Analysis'            |
//| Type=SignalAdvanced                                              |
//| Name=Dual Regression Analysis                                    |
//| ShortName=DUAL_RA                                                |
//| Class=CSignalDUAL_RA                                             |
//| Page=signal_dual_ra                                              |
//| Parameter=Size,int,10,Number of indepenedent variables           |
//| Parameter=OpenCollinearity,int,1,Open Collinearity mode          |
//| Parameter=OpenDetermination,double,0.0,Open Determination threshold   |
//| Parameter=CloseCollinearity,int,1,Close Collinearity mode        |
//| Parameter=CloseDetermination,double,0.0,Close Determination threshold |
//| Parameter=OpenError,int,0,Open Error check Type                  |
//| Parameter=OpenData,int,1,Open Data Type                          |
//| Parameter=CloseError,int,0,Close Error check Type                |
//| Parameter=CloseData,int,1,Close Data Type                        |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CSignalDUAL_RA.                                            |
//| Purpose: Class of generator of trade signals based on            |
//|          the Dual Regression Analysis of Open and Close.         |
//| Is derived from the CExpertSignal class.                         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include             <Math\Stat\stat.mqh>
#include             <Math\Alglib\alglib.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum Echeck
  {
      CHECK_Y=0,           // check for y only
      CHECK_E=1,           // check for the error only
      CHECK_ALL=2,         // check for both the y and the error
      CHECK_NONE=-1        // do not use collinearity checks
  };

enum Edata
  {
      DATA_TREND=0,        // changes in moving average close
      DATA_RANGE=1         // changes in close
  };

enum Eerror
  {
      ERROR_LAST=0,        // use the last error
      ERROR_STANDARD=1     // use standard error
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSignalDUAL_RA : public CExpertSignal
  {
protected:
   CiMA              m_h_ma;             // highs MA handle
   CiMA              m_l_ma;             // lows MA handle
   CiATR             m_ATR;
   //--- adjusted parameters
   int               m_size;
   double            m_open_determination,m_close_determination;
   int               m_open_collinearity,m_open_data,m_open_error;
   int               m_close_collinearity,m_close_data,m_close_error;
public:
                     CSignalDUAL_RA();
                    ~CSignalDUAL_RA();
   //--- methods of setting adjustable parameters
   
   //--- PARAMETER FOR SETTING THE NUMBER OF INDEPENDENT VARIABLES
   void              Size(int value)                  { m_size=value;                  }
   
   //--- PARAMETERS FOR SETTING THE OPEN 'THRESHOLD' FOR THE EXPERTSIGNAL CLASS
   void              OpenCollinearity(int value)      { m_open_collinearity=value;     }
   void              OpenDetermination(double value)  { m_open_determination=value;    }
   void              OpenError(int value)             { m_open_error=value;            }
   void              OpenData(int value)              { m_open_data=value;             }
   
   //--- PARAMETERS FOR SETTING THE CLOSE 'THRESHOLD' FOR THE EXPERTSIGNAL CLASS
   void              CloseCollinearity(int value)     { m_close_collinearity=value;    }
   void              CloseDetermination(double value) { m_close_determination=value;   }
   void              CloseError(int value)            { m_close_error=value;           }
   void              CloseData(int value)             { m_close_data=value;            }
   
   //--- method of verification of settings
   virtual bool      ValidationSettings(void);
   //--- method of creating the indicator and timeseries
   virtual bool      InitIndicators(CIndicators *indicators);
   //--- methods for detection of levels of entering the market
   virtual bool      OpenLongParams(double &price,double &sl,double &tp,datetime &expiration);
   virtual bool      OpenShortParams(double &price,double &sl,double &tp,datetime &expiration);
   //--- methods of checking if the market models are formed
   virtual int       LongCondition(void);
   virtual int       ShortCondition(void);
protected:
   //--- method of initialization of the oscillator
   bool              InitRA(CIndicators *indicators);
   //--- methods of getting data
   int               CheckDetermination(int ind,bool close);
   double            CheckCollinearity(int ind,bool close);
   //
   double            GetY(int ind,bool close);
   double            GetE(int ind,bool close);
   
   double            Data(int ind,bool close);
   //
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSignalDUAL_RA::CSignalDUAL_RA() :  m_size(10),
                          m_open_collinearity(1),
                          m_open_determination(0.5),
                          m_close_collinearity(1),
                          m_close_determination(0.5),
                          m_open_error(0),
                          m_close_error(0),
                          m_open_data(1),
                          m_close_data(1)
  {
//--- initialization of protected data
   m_used_series=USE_SERIES_HIGH+USE_SERIES_LOW;
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CSignalDUAL_RA::ValidationSettings(void)
  {
//--- validation settings of additional filters
   if(!CExpertSignal::ValidationSettings())
      return(false);
//--- initial data checks
   if(m_size<=2)
     {
      printf(__FUNCTION__+": data set must be greater than 2");
      return(false);
     }
     
   if(m_open_collinearity<-1||m_open_collinearity>2)
     {
      printf(__FUNCTION__+": open collinearity mode out of range");
      return(false);
     }
     
   if(m_close_collinearity<-1||m_close_collinearity>2)
     {
      printf(__FUNCTION__+": close collinearity mode out of range");
      return(false);
     }
     
   if(m_open_error<0||m_open_error>1)
     {
      printf(__FUNCTION__+": open error type out of range");
      return(false);
     }
     
   if(m_close_error<0||m_close_error>1)
     {
      printf(__FUNCTION__+": close error type out of range");
      return(false);
     }
     
   if(m_open_data<0||m_open_data>1)
     {
      printf(__FUNCTION__+": open data type out of range");
      return(false);
     }
     
   if(m_close_data<0||m_close_data>1)
     {
      printf(__FUNCTION__+": close data type out of range");
      return(false);
     }

//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool CSignalDUAL_RA::InitIndicators(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- initialization of indicators and timeseries of additional filters
   if(!CExpertSignal::InitIndicators(indicators))
      return(false);
//--- create and initialize RSI oscillator
   if(!InitRA(indicators))
      return(false);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialize RSI oscillators.                                      |
//+------------------------------------------------------------------+
bool CSignalDUAL_RA::InitRA(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- add object to collection

//--- initialize object
   if(!m_h_ma.Create(m_symbol.Name(),m_period,m_size,0,MODE_SMA,PRICE_HIGH))
     {
      printf(__FUNCTION__+": error highs MA indicator");
      return(false);
     }
   if(!m_l_ma.Create(m_symbol.Name(),m_period,m_size,0,MODE_SMA,PRICE_LOW))
     {
      printf(__FUNCTION__+": error lows MA indicator");
      return(false);
     }
//--- initialize ATR indicator
   if(!m_ATR.Create(m_symbol.Name(),m_period,m_size))
     {
      printf(__FUNCTION__+": error initializing ATR indicator");
      return(false);
     }


//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Detecting the levels for buying                                  |
//+------------------------------------------------------------------+
bool CSignalDUAL_RA::OpenLongParams(double &price,double &sl,double &tp,datetime &expiration)
  {
   CExpertSignal *general=(m_general!=-1) ? m_filters.At(m_general) : NULL;
//---
   if(general==NULL)
     {
      m_ATR.Refresh(-1);
      //--- if a base price is not specified explicitly, take the current market price
      double base_price=(m_base_price==0.0) ? m_symbol.Ask() : m_base_price;
      
      //--- price overload that sets entry price to be based on ATR
      price      =m_symbol.NormalizePrice(base_price-(m_price_level*(m_ATR.Main(0)/m_symbol.Point()))*PriceLevelUnit());
      
      sl         =0.0;
      tp         =0.0;
      expiration+=m_expiration*PeriodSeconds(m_period);
      return(true);
     }
//---
   return(general.OpenLongParams(price,sl,tp,expiration));
  }
//+------------------------------------------------------------------+
//| Detecting the levels for selling                                 |
//+------------------------------------------------------------------+
bool CSignalDUAL_RA::OpenShortParams(double &price,double &sl,double &tp,datetime &expiration)
  {
   CExpertSignal *general=(m_general!=-1) ? m_filters.At(m_general) : NULL;
//---
   if(general==NULL)
     {
      m_ATR.Refresh(-1);
      //--- if a base price is not specified explicitly, take the current market price
      double base_price=(m_base_price==0.0) ? m_symbol.Bid() : m_base_price;
      
      //--- price overload that sets entry price to be based on ATR
      price      =m_symbol.NormalizePrice(base_price+(m_price_level*(m_ATR.Main(0)/m_symbol.Point()))*PriceLevelUnit());
      
      sl         =0.0;
      tp         =0.0;
      expiration+=m_expiration*PeriodSeconds(m_period);
      return(true);
     }
//---
   return(general.OpenShortParams(price,sl,tp,expiration));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CSignalDUAL_RA::LongCondition(void)
   {
      int _check=CheckDetermination(StartIndex(),PositionSelect(m_symbol.Name()));
      if(_check>0){ return(_check); }
      
      return(0);
   }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CSignalDUAL_RA::ShortCondition(void)
   {
      int _check=CheckDetermination(StartIndex(),PositionSelect(m_symbol.Name()));
      if(_check<0){ return((int)fabs(_check)); }
      
      return(0);
   }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CSignalDUAL_RA::Data(int ind,bool close)
   {
      if(!close)
      {
         if(Edata(m_open_data)==DATA_TREND)
         {
            m_h_ma.Refresh(-1);
            return((m_l_ma.Main(ind)-m_l_ma.Main(ind+1))-(m_h_ma.Main(ind)-m_h_ma.Main(ind+1)));
         }
         else if(Edata(m_open_data)==DATA_RANGE)
         {
            return((Low(ind)-Low(ind+1))-(High(ind)-High(ind+1)));
         }
      }
      else if(close)
      {
         if(Edata(m_close_data)==DATA_TREND)
         {
            m_h_ma.Refresh(-1);
            return((m_l_ma.Main(ind)-m_l_ma.Main(ind+1))-(m_h_ma.Main(ind)-m_h_ma.Main(ind+1)));
         }
         else if(Edata(m_close_data)==DATA_RANGE)
         {
            return((Low(ind)-Low(ind+1))-(High(ind)-High(ind+1)));
         }
      }
      
      return(0.0);
   }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CSignalDUAL_RA::GetE(int ind,bool close)
  {
      if(!close)
      {
         if(Eerror(m_open_error)==ERROR_STANDARD)
         {
            double _se=0.0;
            for(int r=0;r<m_size;r++) { _se+=pow(Data(r,close)-GetY(r+1,close),2.0); }
            _se=sqrt(_se/(m_size-1)); _se=_se/sqrt(m_size); return(_se);
         }
         else if(Eerror(m_open_error)==ERROR_LAST){ return(Data(ind,close)-GetY(ind+1,close)); }
      }
      else if(close)
      {
         if(Eerror(m_close_error)==ERROR_STANDARD)
         {
            double _se=0.0;
            for(int r=0;r<m_size;r++){  _se+=pow(Data(r,close)-GetY(r+1,close),2.0); }
            _se=sqrt(_se/(m_size-1)); _se=_se/sqrt(m_size); return(_se);
         }
         else if(Eerror(m_close_error)==ERROR_LAST){ return(Data(ind,close)-GetY(ind+1,close)); }
      }
//---
      return(Data(ind,close)-GetY(ind+1,close));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CSignalDUAL_RA::GetY(int ind,bool close)
  {
      double _y=0.0;
      
      CMatrixDouble _a;_a.Resize(m_size,m_size);
      double _b[];ArrayResize(_b,m_size);ArrayInitialize(_b,0.0);
      
      for(int r=0;r<m_size;r++)
      {
         _b[r]=Data(r,close);
         
         for(int c=0;c<m_size;c++)
         {
            _a[r].Set(c,Data(r+c,close));
         }
      }
      
      int _info=0;
      CDenseSolver _S;
      CDenseSolverReport _r;
      double _x[];ArrayResize(_x,m_size);ArrayInitialize(_x,0.0);
      
      _S.RMatrixSolve(_a,m_size,_b,_info,_r,_x);
      
      for(int r=0;r<m_size;r++)
      {
         _y+=(Data(r,close)*_x[r]);
      }
      //---
      return(_y);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CSignalDUAL_RA::CheckDetermination(int ind,bool close)
  {
      int _check=0;
      m_h_ma.Refresh(-1);m_l_ma.Refresh(-1);
      double _det=0.0,_ss_res=0.0,_ss_tot=0.0;
      
      for(int r=0;r<m_size;r++)
      {
         _ss_res+=pow(Data(r,close)-GetY(r+1,close),2.0); 
         _ss_tot+=pow(Data(r,close)-((m_l_ma.Main(r)-m_l_ma.Main(r+1))-(m_h_ma.Main(r)-m_h_ma.Main(r+1))),2.0);
      }
      
      if(_ss_tot!=0.0)
      {
         _det=(1.0-(_ss_res/_ss_tot));
         if(_det>=m_open_determination)
         {
            double _threshold=0.0;
            for(int r=0; r<m_size; r++){ _threshold=fmax(_threshold,fabs(Data(r,close))); }
         
            double _y=CheckCollinearity(ind,close);
            
            _check=int(round(100.0*_y/fmax(fabs(_y),fabs(_threshold))));
         }
      }
//---
      return(_check);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CSignalDUAL_RA::CheckCollinearity(int ind,bool close)
  {
      double _check=0.0;
      double _c=0.0,_array_1[],_array_2[],_r=0.0;
      ArrayResize(_array_1,m_size);ArrayResize(_array_2,m_size);
      ArrayInitialize(_array_1,0.0);ArrayInitialize(_array_2,0.0);
      for(int s=0; s<m_size; s++)
      {
         _array_1[s]=Data(ind+s,close);
         _array_2[s]=Data(m_size+ind+s,close);
      }
      _c=1.0/(2.0+fmin(-1.0,MathCorrelationSpearman(_array_1,_array_2,_r)));
      
      
      if(!close)
      {
         if(Echeck(m_open_collinearity)==CHECK_Y){ _check=(_c*GetY(ind,close))+GetE(ind,close);          }
         else if(Echeck(m_open_collinearity)==CHECK_E){ _check=GetY(ind,close)+(_c*GetE(ind,close));     }
         else if(Echeck(m_open_collinearity)==CHECK_ALL){ _check=_c*(GetY(ind,close)+GetE(ind,close));   }
         else if(Echeck(m_open_collinearity)==CHECK_NONE){ _check=GetY(ind,close)+GetE(ind,close);       }
      }
      else if(close)
      {
         if(Echeck(m_close_collinearity)==CHECK_Y){ _check=(_c*GetY(ind,close))+GetE(ind,close);          }
         else if(Echeck(m_close_collinearity)==CHECK_E){ _check=GetY(ind,close)+(_c*GetE(ind,close));     }
         else if(Echeck(m_close_collinearity)==CHECK_ALL){ _check=_c*(GetY(ind,close)+GetE(ind,close));   }
         else if(Echeck(m_close_collinearity)==CHECK_NONE){ _check=GetY(ind,close)+GetE(ind,close);       }
      }
      
//---
      return(_check);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSignalDUAL_RA::~CSignalDUAL_RA()
  {
  }
//+------------------------------------------------------------------+
