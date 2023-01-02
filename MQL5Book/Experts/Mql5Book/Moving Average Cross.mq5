//+------------------------------------------------------------------+
//|                                             Moving Average Cross |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+

#property copyright "Andrew Young"
#property link      "http://www.expertadvisorbook.com"
#property description "A dual moving average cross with timer, new bar check, money management, trailing stop and break even stop"

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You
 may modify it if necessary. You may even share it, provided
 the copyright above is present. No commercial use permitted. 
*/


// Trade
#include <Mql5Book\Trade.mqh>
CTrade Trade;

// Price
#include <Mql5Book\Price.mqh>
CBars Bar;

// Money management
#include <Mql5Book\MoneyManagement.mqh>

// Trailing stops
#include <Mql5Book\TrailingStops.mqh>
CTrailing Trail;

// Timer
#include <Mql5Book\Timer.mqh>
CTimer Timer;
CNewBar NewBar;

// Indicators 
#include <Mql5Book\Indicators.mqh>
CiMA FastMA;
CiMA SlowMA;


//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+

input ulong Slippage = 3;
input bool TradeOnNewBar = true;

sinput string MM; 	// Money Management
input bool UseMoneyManagement = true;
input double RiskPercent = 2;
input double FixedVolume = 0.1;

sinput string SL; 	// Stop Loss & Take Profit
input int StopLoss = 0;
input int TakeProfit = 0;

sinput string TS;		// Trailing Stop
input bool UseTrailingStop = false;
input int TrailingStop = 0;
input int MinimumProfit = 0;
input int Step = 0; 

sinput string BE;		// Break Even
input bool UseBreakEven = false;
input int BreakEvenProfit = 0;
input int LockProfit = 0;

sinput string FaMA;	// Fast MA
input int FastMAPeriod = 10;
input ENUM_MA_METHOD FastMAMethod = 0;
input int FastMAShift = 0;
input ENUM_APPLIED_PRICE FastMAPrice = PRICE_CLOSE;

sinput string SlMA;	// Slow MA
input int SlowMAPeriod = 20;
input ENUM_MA_METHOD SlowMAMethod = 0;
input int SlowMAShift = 0;
input ENUM_APPLIED_PRICE SlowMAPrice = PRICE_CLOSE;

sinput string TI; 	// Timer
input bool UseTimer = false;
input int StartHour = 0;
input int StartMinute = 0;
input int EndHour = 0;
input int EndMinute = 0;
input bool UseLocalTime = false;



//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+

bool glBuyPlaced, glSellPlaced;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
	FastMA.Init(_Symbol,_Period,FastMAPeriod,FastMAShift,FastMAMethod,FastMAPrice);
	SlowMA.Init(_Symbol,_Period,SlowMAPeriod,SlowMAShift,SlowMAMethod,SlowMAPrice);
	
	Trade.Deviation(Slippage);
	
   return(0);
}



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{

	// Check for new bar
	bool newBar = true;
	int barShift = 0;
	
	if(TradeOnNewBar == true) 
	{
		newBar = NewBar.CheckNewBar(_Symbol,_Period);
		barShift = 1;
	}
	
	
	// Timer
	bool timerOn = true;
	if(UseTimer == true)
	{
		timerOn = Timer.DailyTimer(StartHour,StartMinute,EndHour,EndMinute,UseLocalTime);
	}
	
	
	// Update prices
	Bar.Update(_Symbol,_Period);
	
	
	// Order placement
	if(newBar == true && timerOn == true)
	{
		
		// Money management
		double tradeSize;
		if(UseMoneyManagement == true) tradeSize = MoneyManagement(_Symbol,FixedVolume,RiskPercent,StopLoss);
		else tradeSize = VerifyVolume(_Symbol,FixedVolume);
		
		
		// Open buy order
		if(FastMA.Main(barShift) > SlowMA.Main(barShift) && PositionType() != POSITION_TYPE_BUY && glBuyPlaced == false)
		{
			glBuyPlaced = Trade.Buy(_Symbol,tradeSize);
		
			if(glBuyPlaced == true)  
			{
				double openPrice = PositionOpenPrice(_Symbol);
				
				double buyStop = BuyStopLoss(_Symbol,StopLoss,openPrice);
				if(buyStop > 0) AdjustBelowStopLevel(_Symbol,buyStop);
				
				double buyProfit = BuyTakeProfit(_Symbol,TakeProfit,openPrice);
				if(buyProfit > 0) AdjustAboveStopLevel(_Symbol,buyProfit);
				
				if(buyStop > 0 || buyProfit > 0) Trade.ModifyPosition(_Symbol,buyStop,buyProfit);
				glSellPlaced = false;
			} 
		}
		
		
		// Open sell order
		if(FastMA.Main(barShift) < SlowMA.Main(barShift) && PositionType() != POSITION_TYPE_SELL && glSellPlaced == false)
		{
			glSellPlaced = Trade.Sell(_Symbol,tradeSize);
			
			if(glSellPlaced == true)
			{
				double openPrice = PositionOpenPrice(_Symbol);
				
				double sellStop = SellStopLoss(_Symbol,StopLoss,openPrice);
				if(sellStop > 0) sellStop = AdjustAboveStopLevel(_Symbol,sellStop);
				
				double sellProfit = SellTakeProfit(_Symbol,TakeProfit,openPrice);
				if(sellProfit > 0) sellProfit = AdjustBelowStopLevel(_Symbol,sellProfit);
				
				if(sellStop > 0 || sellProfit > 0) Trade.ModifyPosition(_Symbol,sellStop,sellProfit);
				glBuyPlaced = false;
			} 
		}
		
		
	} // Order placement end
	
	
	// Break even
	if(UseBreakEven == true && PositionType(_Symbol) != -1)
	{
		Trail.BreakEven(_Symbol,BreakEvenProfit,LockProfit);
	}
	
	
	// Trailing stop
	if(UseTrailingStop == true && PositionType(_Symbol) != -1)
	{
		Trail.TrailingStop(_Symbol,TrailingStop,MinimumProfit,Step);
	}


}


