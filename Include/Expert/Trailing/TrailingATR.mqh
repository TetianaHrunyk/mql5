//+------------------------------------------------------------------+
//|                                                   TrailingMA.mqh |
//|                   Copyright 2009-2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <Expert\ExpertTrailing.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Trailing Stop based on ATR                                 |
//| Type=Trailing                                                    |
//| Name=ATR                                                         |
//| Class=CTrailingATR                                               |
//| Page=                                                            |
//| Parameter=Period,int,12,Period of ATR                            |
//| Parameter=Weight,double,2.0,Weight of ATR multiple               |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CTrailingATR.                                              |
//| Purpose: Class of trailing stops based on ATR.                   |
//|              Derives from class CExpertTrailing.                 |
//+------------------------------------------------------------------+
class CTrailingATR : public CExpertTrailing
  {
protected:
   CiATR             *m_ATR;
   //--- input parameters
   int               m_atr_period;
   double            m_atr_weight;

public:
                     CTrailingATR(void);
                    ~CTrailingATR(void);
   //--- methods of initialization of protected data
   void              Period(int period)                  { m_atr_period=period;   }
   void              Weight(double weight)               { m_atr_weight=weight;   }
   
   virtual bool      InitIndicators(CIndicators *indicators);
   virtual bool      ValidationSettings(void);
   //---
   virtual bool      CheckTrailingStopLong(CPositionInfo *position,double &sl,double &tp);
   virtual bool      CheckTrailingStopShort(CPositionInfo *position,double &sl,double &tp);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
void CTrailingATR::CTrailingATR(void) : m_ATR(NULL),
                                       m_atr_period(12),
                                       m_atr_weight(2.0)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
void CTrailingATR::~CTrailingATR(void)
  {
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CTrailingATR::ValidationSettings(void)
  {
   if(!CExpertTrailing::ValidationSettings())
      return(false);
//--- initial data checks
   if(m_atr_period<=0)
     {
      printf(__FUNCTION__+": period MA must be greater than 0");
      return(false);
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Checking for input parameters and setting protected data.        |
//+------------------------------------------------------------------+
bool CTrailingATR::InitIndicators(CIndicators *indicators)
  {
//--- check
   if(indicators==NULL)
      return(false);
//--- create ATR indicator
   if(m_ATR==NULL)
      if((m_ATR=new CiATR)==NULL)
        {
         printf(__FUNCTION__+": error creating object");
         return(false);
        }
//--- add ATR indicator to collection
   if(!indicators.Add(m_ATR))
     {
      printf(__FUNCTION__+": error adding object");
      delete m_ATR;
      return(false);
     }
//--- initialize ATR indicator
   if(!m_ATR.Create(m_symbol.Name(),m_period,m_atr_period))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
     
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Checking trailing stop and/or profit for long position.          |
//+------------------------------------------------------------------+
bool CTrailingATR::CheckTrailingStopLong(CPositionInfo *position,double &sl,double &tp)
  {
//--- check
   if(position==NULL)
      return(false);
//---
   m_ATR.Refresh(-1);
   double level =NormalizeDouble(m_symbol.Bid()-m_symbol.StopsLevel()*m_symbol.Point(),m_symbol.Digits());
   
   //--- sl adjustment to be based on ATR
   double new_sl=NormalizeDouble(level-(m_atr_weight*(m_ATR.Main(0)/m_symbol.Point())),m_symbol.Digits());
   
   double pos_sl=position.StopLoss();
   double base  =(pos_sl==0.0) ? position.PriceOpen() : pos_sl;
//---
   sl=EMPTY_VALUE;
   tp=EMPTY_VALUE;
   if(new_sl>base && new_sl<level)
      sl=new_sl;
//---
   return(sl!=EMPTY_VALUE);
  }
//+------------------------------------------------------------------+
//| Checking trailing stop and/or profit for short position.         |
//+------------------------------------------------------------------+
bool CTrailingATR::CheckTrailingStopShort(CPositionInfo *position,double &sl,double &tp)
  {
//--- check
   if(position==NULL)
      return(false);
//---
   m_ATR.Refresh(-1);
   double level =NormalizeDouble(m_symbol.Ask()+m_symbol.StopsLevel()*m_symbol.Point(),m_symbol.Digits());
   
   //--- sl adjustment to be based on ATR
   double new_sl=NormalizeDouble(level+(m_atr_weight*(m_ATR.Main(0)/m_symbol.Point())),m_symbol.Digits());
   
   double pos_sl=position.StopLoss();
   double base  =(pos_sl==0.0) ? position.PriceOpen() : pos_sl;
//---
   sl=EMPTY_VALUE;
   tp=EMPTY_VALUE;
   if(new_sl<base && new_sl>level)
      sl=new_sl;
//---
   return(sl!=EMPTY_VALUE);
  }
//+------------------------------------------------------------------+
