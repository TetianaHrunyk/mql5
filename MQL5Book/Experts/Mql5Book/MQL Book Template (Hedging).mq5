//+------------------------------------------------------------------+
//| 									 Expert Advisor Programming - Template |
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
#include <Mql5Book\TradeHedge.mqh>
CTradeHedge Trade;
CPositions Positions;

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
input ulong MagicNumber = 123;
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

ulong glBuyTicket, glSellTicket;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
	
	Trade.MagicNumber(MagicNumber);
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
		
		
		// Open buy order
		if(Positions.Buy(MagicNumber) == 0)
		{
			glBuyTicket = Trade.Buy(_Symbol,tradeSize);
		
			if(glBuyTicket > 0)  
			{
				double openPrice = PositionOpenPrice(glBuyTicket);
				
				double buyStop = BuyStopLoss(_Symbol,StopLoss,openPrice);
				if(buyStop > 0) AdjustBelowStopLevel(_Symbol,buyStop);
				
				double buyProfit = BuyTakeProfit(_Symbol,TakeProfit,openPrice);
				if(buyProfit > 0) AdjustAboveStopLevel(_Symbol,buyProfit);
				
				if(buyStop > 0 || buyProfit > 0) Trade.ModifyPosition(glBuyTicket,buyStop,buyProfit);
				glSellTicket = 0;
			} 
		}
		
		
		// Open sell order
		if(Positions.Sell(MagicNumber) == 0)
		{
			glSellTicket = Trade.Sell(_Symbol,tradeSize);
			
			if(glSellTicket > 0)
			{
				double openPrice = PositionOpenPrice(glSellTicket);
				
				double sellStop = SellStopLoss(_Symbol,StopLoss,openPrice);
				if(sellStop > 0) sellStop = AdjustAboveStopLevel(_Symbol,sellStop);
				
				double sellProfit = SellTakeProfit(_Symbol,TakeProfit,openPrice);
				if(sellProfit > 0) sellProfit = AdjustBelowStopLevel(_Symbol,sellProfit);
				
				if(sellStop > 0 || sellProfit > 0) Trade.ModifyPosition(glSellTicket,sellStop,sellProfit);
				glBuyTicket = 0;
			} 
		}
		
	} // Order placement end
	
	
	// Get position tickets
	ulong tickets[];
	Positions.GetTickets(MagicNumber, tickets);
	int numTickets = ArraySize(tickets);
	
	
	// Break even
	if(UseBreakEven == true && numTickets > 0)
	{
		for(int i = 0; i < numTickets; i++)
		{
		   Trail.BreakEven(tickets[i], BreakEvenProfit, LockProfit);
		}
	}
	
	
	// Trailing stop
	if(UseTrailingStop == true && numTickets > 0)
	{
		for(int i = 0; i < numTickets; i++)
		{
		   Trail.TrailingStop(tickets[i], TrailingStop, MinimumProfit, Step);
		}
	}


}


