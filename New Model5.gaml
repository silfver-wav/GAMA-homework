/**
* Name: NewModel5
* Based on the internal empty template. 
* Author: linus
* Tags: 
*/


model NewModel5

/* Insert your model definition here */

global 
{
	int numberOfQueens <- 8;
	
	
	
	init { 
		int index <- 0;
		create Queen number: numberOfQueens;
		
		loop counter from: 1 to: numberOfQueens {
        	Queen queen <- Queen[counter - 1];
        	queen <- queen.setId(index);
        	queen <- queen.initializeCell();
        	
        	index <- index + 1;
        }
	}
	
}

species Queen skills: [fipa]{
    
	ChessBoard myCell; 
	int id; 
	int index <- 0;
	Queen sucessor;
	Queen predecessor;
	bool init <- true;
	bool propose <- false;
	bool yourTurn <- false;
	message msg <- nil;
	bool active <- false;
	
	
	
	reflex init when: init {
		int i <- 0;
		loop counter from: 1 to: numberOfQueens {
			if (i = 0 and id = 0) {
				propose <- true;
				yourTurn <- true;
        		sucessor <- Queen[counter];
        		active <- true;
			} else if (i = (numberOfQueens - 1) and  id = (numberOfQueens - 1)) {
				predecessor <- Queen[counter - 2];
			} else if (i = id) {
				sucessor <- Queen[counter];
				predecessor <- Queen[counter - 2];
			}
			
        	i <- i + 1;
        }

		init <- false;
	}
	
    reflex getMessage when: !empty(informs) {
    	message informMsg <- informs[0];
		write '(Time ' + time + '): ' + name + ' receives a info message from ' + agent(informMsg.sender).name + ' with content: ' + informMsg.contents;
		/*
		if ('Return' = informMsg.contents[0] and index = numberOfQueens) {
			do start_conversation (to: [predecessor], protocol: 'no-protocol', performative: 'inform', contents: ['Return']);
			index <- id;
			active <- false;	
		}
		*/	
    	propose <- true;
		yourTurn <- true;
			
    	do end_conversation message:informMsg contents: ['End!'];
    }
	
	reflex rejectedPos when: !empty(reject_proposals) {
		message r <- reject_proposals[0];
		write '(Time ' + time + '): ' + name + ' receives a reject_proposals message from ' + agent(r.sender).name + ' with content: ' + r.contents;
		do end_conversation message:r contents: ['End!'];
				
		if (yourTurn) {
		/*			
			if (index = numberOfQueens) {
				write '';
				do start_conversation (to: [predecessor], protocol: 'no-protocol', performative: 'inform', contents: ['Return']);
				yourTurn <- false;
				active <- false;
				index <- 0;
			} else {				
				propose <- true;
			}
		*/
			propose <- true;
		} else {
			do reject_proposal with: (message: msg, contents: ['pos is not okay', msg.contents[2]]);
		}
	}
	
	reflex acceptedPropsal when: !empty(accept_proposals) {
		message a <- accept_proposals[0];
		
		write '(Time ' + time + '): ' + name + ' receives a accept_proposals message from ' + agent(a.sender).name + ' with content: ' + a.contents;			
		do end_conversation message:a contents: ['End!'];
		
		if (!propose and yourTurn) {
			write '';
			if (sucessor !=nil) {
				do start_conversation (to: [sucessor], protocol: 'no-protocol', performative: 'inform', contents: ['Move']);	
			}
			
			yourTurn <- false;
		} else if (!yourTurn) {
			int row <- msg.contents[0];
			int col <- msg.contents[1];
			do accept_proposal with: (message: msg, contents: ['pos ['+row+','+col+'] is okay', msg.contents[2]]);	
		}
	}

	reflex backTrack when: yourTurn and (index = numberOfQueens) and propose {
		write '';
		do start_conversation (to: [predecessor], protocol: 'no-protocol', performative: 'inform', contents: ['Return']);
		yourTurn <- false;
		active <- false;
		propose <- false;
		index <- 0;
	}	
       
    reflex sendPosProposal when: propose and yourTurn {
    	myCell <- ChessBoard[id,  mod(index, numberOfQueens)];
		location <- myCell.location;
		
		index <- index + 1;

    	if (predecessor != nil) {
    		write '(Time ' + time + '): ' + name + ' sends cfp messages from with content: ['+myCell.grid_y+','+myCell.grid_x+']';
			do start_conversation (to: [predecessor], protocol: 'fipa-propose', performative: 'cfp', contents: [myCell.grid_y, myCell.grid_x, self]);
    	} else {
    		do start_conversation (to: [sucessor], protocol: 'no-protocol', performative: 'inform', contents: ['Move']);
    		yourTurn <- false;
    	} 
    	active <- true;	    		
		propose <- false;
    }
    
    
    reflex getPos when: !empty(cfps) {
		message cfpMsg <- cfps at 0;

		write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(cfpMsg.sender).name + ' with content: ' + cfpMsg.contents;
			
		bool flag <- true;
		int edge <- numberOfQueens - 1;
	
		if (cfpMsg.contents[0] = myCell.grid_y) {
			do reject_proposal with: (message: cfpMsg, contents: ['row is ocupied']);
			flag <- false;
		}	
		
		if (flag) {
			int r <- int(cfpMsg.contents[0]);
			int c <- int(cfpMsg.contents[1]);
			
	    	loop counter from: 1 to: numberOfQueens {
	    		if (c = myCell.grid_x and r = myCell.grid_y) {
	    			do reject_proposal with: (message: cfpMsg, contents: ['diagonal is ocupied', cfpMsg.contents[2]]);
	    			flag <- false;
	    			break;
	    		} else if (r = edge or c = edge) {
	    			break;
	    		}
	    		r <- r + 1;
	    		c <- c + 1;	
	    	}				
		}
		
		if (flag) {			
			int r <- int(cfpMsg.contents[0]);
			int c <- int(cfpMsg.contents[1]);
			
	    	loop while: true {
	    		if (c = myCell.grid_x and r = myCell.grid_y) {
	    			do reject_proposal with: (message: cfpMsg, contents: ['diagonal is ocupied', cfpMsg.contents[2]]);
	    			flag <- false;
	    			break;
	    		} else if (r = 0 or c = 0) {
	    			break;
	    		}
	    		r <- r - 1;
	    		c <- c - 1;	
	    	}	
		}
	
		if (flag) {		
			int r <- int(cfpMsg.contents[0]);
			int c <- int(cfpMsg.contents[1]);
			
			loop while: true {
				if (c = myCell.grid_x and r = myCell.grid_y) {
					do reject_proposal with: (message: cfpMsg, contents: ['diagonal is ocupied', cfpMsg.contents[2]]);
	    			flag <- false;
	    			break;
				} else if (r = 0 or c = 0 or r = edge or c = edge) {
					break;
				}
				r <- r + 1;
				c <- c - 1;	
			}	
		}
	
    	if (flag) {  		
			int r <- int(cfpMsg.contents[0]);
			int c <- int(cfpMsg.contents[1]);
			
	    	loop while: true {
	    		if (c = myCell.grid_x and r = myCell.grid_y) {
	    			do reject_proposal with: (message: cfpMsg, contents: ['diagonal is ocupied', cfpMsg.contents[2]]);
	    			flag <- false;
	    			break;
	    		} else if (r = 0 or c = 0 or r = edge or c = edge) {
	    			break;
	    		}
	    		r <- r - 1;
	    		c <- c + 1;	
	    	}	
    	}
	
		if (flag) {
    		if (predecessor = nil) {
    			int row <- cfpMsg.contents[0];
    			int col <- cfpMsg.contents[1];
    			do accept_proposal with: (message: cfpMsg, contents: ['pos ['+row+','+col+'] is okay', cfpMsg.contents[2]]);
    		} else {
    			do start_conversation (to: [predecessor], protocol: 'fipa-propose', performative: 'cfp', contents: cfpMsg.contents);
    			msg <- cfpMsg;	
    		}    		
	    }		
    }
    

	action setId(int input) {
		id <- input;
	}
	
	action initializeCell {
		myCell <- ChessBoard[0, id];
	}
	
	
	float size <- 30/numberOfQueens;
	
	aspect base {
		if (active) {
			draw circle(size) color: #blue ;	
		}
        
       	location <- myCell.location ;
    }

}


grid ChessBoard width: numberOfQueens height: numberOfQueens { 
	
	init{
		if(even(grid_x) and even(grid_y)){
			color <- #black;
		}
		else if (!even(grid_x) and !even(grid_y)){
			color <- #black;
		}
		else {
			color <- #white;
		}
	}
}


experiment NQueensProblem type: gui{
	output{
		display ChessBoard{
			grid ChessBoard border: #black ;
			species Queen aspect: base;
		}
	}
}