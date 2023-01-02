//+------------------------------------------------------------------+
//| 	      Expert Advisor Programming - Pending Stop Order Template |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+

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
CBars Price;

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

// Pending
#include <Mql5Book\Pending.mqh>
CPending Pending;



//+------------------------------------------------------------------+
//| Expert information                                               |
//+------------------------------------------------------------------+

#property copyright "Andrew Young"
#property version   "1.00"
#property description ""
#property link      "http://www.expertadvisorbook.com"



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
input int StopLoss = 20;
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
	Price.Update(_Symbol,_Period);
	
	
	// Order placement
	if(newBar == true && timerOn == true)
	{
		
		// Money management
		double tradeSize;
		if(UseMoneyManagement == true) tradeSize = MoneyManagement(_Symbol,FixedVolume,RiskPercent,StopLoss);
		else tradeSize = VerifyVolume(_Symbol,FixedVolume);
		
		
		// Open pending buy stop order
		if(PositionType() != POSITION_TYPE_BUY && glBuyPlaced == false)
		{
			double orderPrice = 0;
			orderPrice = AdjustAboveStopLevel(_Symbol,orderPrice);
			
			double buyStop = BuyStopLoss(_Symbol,StopLoss,orderPrice);
			double buyProfit = BuyTakeProfit(_Symbol,TakeProfit,orderPrice);
			
			glBuyPlaced = Trade.BuyStop(_Symbol,tradeSize,orderPrice,buyStop,buyProfit);
		
			if(glBuyPlaced == true)  
			{
				glSellPlaced = false;
			} 
		}
		
		
		// Open sell order
		if(PositionType() != POSITION_TYPE_SELL && glSellPlaced == false)
		{
			double orderPrice = 0;
			orderPrice = AdjustBelowStopLevel(_Symbol,orderPrice);
			
			double sellStop = SellStopLoss(_Symbol,StopLoss,orderPrice);
			double sellProfit = SellTakeProfit(_Symbol,TakeProfit,orderPrice);
			
			glSellPlaced = Trade.SellStop(_Symbol,tradeSize,orderPrice,sellStop,sellProfit);
		
			if(glSellPlaced == true)  
			{
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


