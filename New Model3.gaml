/**
* Name: NewModel3
* Based on the internal empty template. 
* Author: linus
* Tags: 
*/


model NewModel3

/* Insert your model definition here */

global {
	int numberOfBidders <- 5;	
	int numberOfAuctioneers <- 4;	
	
	int dutchPriceMin <- 1500;
	int dutchPriceMax <- 2000;
	
	int japanesePriceMin <- 150;
	int japanesePriceMax <- 200;
	
	int bidderMin <- 100;
	int bidderMax <- 1500;
	
	int minValue <- 500;
	
	list<string> categories <- ['flowers','saffran'];
	list<string> typeOfAuctions <- ['Dutch','Japanese','Vickrey'];
	
	init {
		create Auctioneer number: numberOfAuctioneers;
		create Bidder number: numberOfBidders;
	}
}



species Auctioneer skills: [fipa] {
	bool running <- false;
	bool snp <- false;
	int value <- 0;
	string category <- '';
	string typeOfAuction <- ''; 
	list<Bidder> bidders <- [];
	
	init {
		category <- categories[rnd(0,length(categories)-1)];
		typeOfAuction <- typeOfAuctions[rnd(0,length(typeOfAuctions)-1)];
		
		if (typeOfAuction = 'Dutch') {
			value <- rnd(dutchPriceMin, dutchPriceMax);
		} else if (typeOfAuction = 'Japanese') {
			value <- rnd(japanesePriceMin, japanesePriceMax);			
		} else {
			value <- rnd(100, 2000);
			write name + ' true value is ' +value;
		}
		
	}
	
	reflex announceAuction when: !running and (time = 0) {
		write '(Time ' + time + '): ' + name + ' annouces ' +typeOfAuction+ ' auction for ' +category;
		do start_conversation (to: list(Bidder), protocol: 'no-protocol', performative: 'inform', contents: ['Start', category, typeOfAuction, value]);
	}
	
	reflex recieveProposals when: !running and !empty(informs) {
		loop informMsg  over: informs {
			if (!(bidders contains informMsg.sender)) {
				write agent(informMsg.sender).name + ' wants to join the auction ' +name;
				bidders <+ informMsg.sender;	
			}
		}
		write 'bidders: ' +bidders;
		if (length(bidders) > 1) {

			running <- true;
			snp <- true;
		} else {
			write name +' cannot start (not enough bidders)';
			do start_conversation (to: list(bidders), protocol: 'no-protocol', performative: 'inform', contents: ['Stop']);	
			do die;
		}
	}
	
		/////////////////////////////////////// Dutch //////////////////////////////////////////////////
		
	reflex acceptedDutchPropsal when: running and !empty(accept_proposals) and typeOfAuction = 'Dutch' {
		bool winner <- true;
		loop a over: accept_proposals {
			if (winner) {
				write 'we have a winner';
				write agent(a.sender).name + ' is the winner with of ' +name;
				write '/////////////////////////////////////////////////////////';
			}
			do end_conversation message:a contents: ['End!'] ;
		}
		
		do die; //end_conversation;
	}
	
	reflex rejectedDutchPropsal when: running and !empty(reject_proposals) and typeOfAuction = 'Dutch' {
		value <- value - 100;
		snp <- true;
		if (value < minValue) {
			write name + ' price has gone below the minimum value (' + minValue + '). Auction is terminated!';
			
			loop rejectMsg over: reject_proposals {
				do end_conversation message:rejectMsg contents: ['End!'];
			}
			do die;
		}
	}
	
	reflex sendDutchProposalToAllBidders when: running and snp and typeOfAuction = 'Dutch'{
		write '(Time ' + time + '): ' + name + ' sent price '+value+' to bidders.';
		do start_conversation (to: list(bidders), protocol: 'no-protocol', performative: 'cfp', contents: [value]);
		snp <- false;
	}
	
	
	/////////////////////////////////////// Japanese //////////////////////////////////////////////////
	
	reflex rejectedJapanesePropsal when: running and !empty(reject_proposals) and typeOfAuction = 'Japanese' {		
		loop r over: reject_proposals {
			if ((bidders contains r.sender)) {
				write agent(r.sender).name + ' removed from ' +name;
				remove item:r.sender from:bidders;	
				do end_conversation message:r contents: ['End!'];
			}
		}
		
		if (empty(bidders)) {
			write name + ' ends with no winners';
			do die;
		}
	}
	
	reflex acceptedJapanesePropsal when: running and !empty(accept_proposals) and typeOfAuction = 'Japanese' {
		if (length(bidders) = 1) {
			loop a over: accept_proposals {
				if (a.sender = bidders[0]) {
					write 'we have a winner';
					write agent(a.sender).name + ' is the winner with of ' +name;
					write '/////////////////////////////////////////////////////////';
					do end_conversation message:a contents: ['End!'];
				}
			}
			do die;
		} else {
			loop a over: accept_proposals {
				do end_conversation message:a contents: ['End!'];		
			}
			
			value <- value + 200;
			snp <- true;
		}
	}
	
	reflex sendJapaneseProposalToAllBidders when: running and snp and typeOfAuction = 'Japanese'{
		if (length(bidders) > 1) {
			write '(Time ' + time + '): ' + name + ' sent price '+value+' to bidders.';
			do start_conversation (to: list(bidders), protocol: 'no-protocol', performative: 'cfp', contents: [value]);
			snp <- false;	
		}
	}
	
	/*
		reflex priceToHigh when: running and length(bidders) = 0 {
		do die;
	} 
	 */
	
	
	/////////////////////////////////////////// Vickrey ////////////////////////////////////////////
	
	reflex recieveVickreyBids when: running and typeOfAuction = 'Vickrey' and !empty(proposes) {
		write name + ' received bids';
		
		int max <- 0;
		int smax <-0;
		message winner <- nil;
		
		loop p over: proposes {
			write agent(p.sender).name + ' bids ' + p.contents[0];
			int bid <- int(p.contents[0]);
			if (bid > max) {
				smax <- max;
				max <- bid;
				winner <- p;
			} else if (bid > smax) {
				smax <- bid;
			}
			//do end_conversation message: p contents: ['End!'];
		}
		
		
		write 'max: '+max;
		write 'smax: '+smax;
		
		write '///////////////////////////////////////////////////////////////';
		write agent(winner.sender).name + ' is the winner with ' +max+ ' bid has to pay ' +smax;
		do die;
	}
	
}


species Bidder skills: [fipa] {
	int mw2p <- rnd(bidderMin,bidderMax);
	string want <- '';
	bool won <- false;
	list<string> types <- [];
	list<Auctioneer> auctioneers <- [];
	
	init {
		want <- categories[rnd(0,length(categories)-1)];
		write name + ' want '+want;
	}
	
	reflex recieveInfo when: !empty(informs) {
		
		loop informMsg over: informs {
			if(informMsg.contents[0] = 'Start' and (want contains informMsg.contents[1]) ) {
				do inform message:informMsg contents: ['Yes'];
				types <+ informMsg.contents[2];
				auctioneers <+ informMsg.sender;
				
			} else if(informMsg.contents[0] = 'Winner') {
				write name + ' won the auction for '+want;
			}
			else if(informMsg.contents[0] = 'Stop')	{
				write name + ' lost the auction for '+want;
				remove item:informMsg.sender from:auctioneers; 
			}	
		}
	}
	
	reflex recievePrice when: !empty(cfp) {
		loop cfpMsg over: cfps {
			//write '(Time ' + time + '): ' + name + ' received an message from ' + agent(cfpMsg.sender).name + ' with content: ' + cfpMsg.contents;	
			int price <- cfpMsg.contents[0];
			
			if (mw2p >= price) {
				write name + ", accept the price " + price + ' for auction: ' +agent(cfpMsg.sender).name;
				do accept_proposal with: (message: cfpMsg, contents: [name + ", accept the price" + price + 'for auction: ' +agent(cfpMsg.sender).name]);
			}
			else
			{
				write name + ", rejects the price " + price + ' for auction: ' +agent(cfpMsg.sender).name;
				do reject_proposal (message: cfpMsg, contents: [name + ", rejects the price" + price + 'for auction: ' +agent(cfpMsg.sender).name]);	
			}
		}
	}
	
	
	reflex vickreyBid when: !empty(auctioneers) {// and type = 'Vickrey' {
		int value <- auctioneers[0].value;
		int bid <- rnd(value + 50, value + 500);
		do start_conversation to: [auctioneers[0]] protocol: 'fipa-propose' performative: 'propose' contents: [bid];
		auctioneers[0] <- nil;
		remove item:auctioneers[0] from:auctioneers; // remove the 1st occurrence of 7
	}
	
}

experiment myExperiment {}