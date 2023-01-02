//+------------------------------------------------------------------+
//|                                             Close All Orders.mq5 |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+

#property copyright   "Andrew Young"
#property link        "http://www.expertadvisorbook.com"
#property description "Close the current position and all orders for the specified chart symbol."

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You
 may modify it if necessary. You may even share it, provided
 the copyright above is present. No commercial use permitted. 
*/


#property script_show_inputs

#include <Mql5Book\Trade.mqh>
CTrade Trade;

#include <Mql5Book\Pending.mqh>
CPending Pending;

input string CloseSymbol = "";


void OnStart()
{
	// Check symbol name
	string useSymbol = CloseSymbol;
	if(CloseSymbol == "") useSymbol = _Symbol;
	
	// Close current position
	if(PositionType(useSymbol) != WRONG_VALUE)
	{
		bool closed = Trade.Close(useSymbol);
		if(closed == true)
		{
			Comment("Position closed on "+useSymbol);
		}
	}
	
	// Close any open pending orders
	if(Pending.TotalPending(useSymbol) > 0)
	{
		// Get pending order tickets
		ulong tickets[];
		Pending.GetTickets(useSymbol,tickets);
		int numTickets = ArraySize(tickets);
		
		// Close orders
		for(int i = 0; i < numTickets; i++)
		{
			Trade.Delete(tickets[i]);
		}
		
		if(Pending.TotalPending(useSymbol) == 0)
		{
			Comment("All pending orders closed on "+useSymbol);
		}
	}
	
}

