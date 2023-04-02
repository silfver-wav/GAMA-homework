/**
* Name: FinalProject
* Based on the internal empty template. 
* Author: linus
* Tags: 
*/


model FinalProject

/* Insert your model definition here */

global {
	int numberOfGuests <- 50;
	
	// Types of Guest types
	list<string> typesOfGuest <- ["Introvert","Party","Bar-Hoppers","Socialite","Stooner"];	
	
	init {
		create Guest number: numberOfGuests; // 50;
		
		loop counter from: 1 to: numberOfGuests {
			Guest my_agent <- Guest[counter - 1];
			my_agent <- my_agent.setName(counter);
		}	

		create Bar number: 1
		{
			location <- {75, 75};
		}
		create Cafe number: 1
		{
			location <- {25, 25};
		}
		
		create Club number: 1
		{
			location <- {50, 50};
		}
	}
}


/**
 * Represents a guest in a simulation.
 */
species Guest skills: [moving, fipa] {
	string guestName <- "Undefined";
	string type <- typesOfGuest[rnd(length(typesOfGuest) - 1)]; // Determines the guest type
    float happines <- 0.5;
    Location target <- nil;
	bool inConversation <- false;    
	// Personality traits for Guest
    float friendliness <- rnd(0.1,1.0);
    float confidence <- rnd(0.1,1.0);
    float open_minded <- rnd(0.1,1.0);
    float crazy <- rnd(0.1,1.0);    
	// The Guest which the guest is currently having a conversation with	
	Guest guest <- nil;
	// Smallbrain that remebers which guest it has talked to
	list<Guest> smallbrain <- nil;
	
    
   /**
    * Sets the name of the guest.
    *
    * @param num the number to use in the guest name
    */
	action setName(int num) {
		guestName <- "Person " + num;
	}
	

    
    /**
	 * Determines where a guest should go based on their type and a randomly generated value.
	 *
	 * @param target the current target location of the guest
	 * @param time the current time
	 */
    reflex whereToGo when: target = nil or time mod 120 = 0 {
    	
    	float rand <- rnd(0.0,1.0);
   
		if (type = "Party") {
	    	if (rand < 0.7) {
			  target <- one_of(Club);	
			} else if (rand < 0.9) {
			  target <- one_of(Bar);
			} else {
			  target <- one_of(Cafe);
			}		
		} else if (type = "Introvert") {
	    	if (rand < 0.7) {
			  target <- one_of(Cafe);	
			} else if (rand < 0.9) {
			  target <- one_of(Bar);
			} else {
			  target <- one_of(Club);
			}				
		} else if (type = "Bar-Hoppers") {
	    	if (rand < 0.7) {
			  target <- one_of(Bar);	
			} else if (rand < 0.9) {
			  target <- one_of(Club);
			} else {
			  target <- one_of(Cafe);
			}	
		} else if (type = "Socialite") {
	    	if (rand < 0.4) {
			  target <- one_of(Club);	
			} else if (rand < 0.7) {
			  target <- one_of(Bar);
			} else {
			  target <- one_of(Cafe);
			}	
		} else if (type = "Stooner") {
	    	if (rand < 0.5) {
			  target <- one_of(Cafe);	
			} else if (rand < 0.9) {
			  target <- one_of(Bar);
			} else {
			  target <- one_of(Club);
			}	
		}
		
    }
    

    /**
	 * Determines the action that a guest should take based on their current target location.
	 *
	 * @param target the current target location of the guest
	 */
	reflex move {
		if (inConversation) {
			return;
		} else if (target != nil) {
			do goto target:target.location;
		} else {
			do wander;
		}		
	}
	
	/**
	 * Modifies the happiness of a guest based on their current location and type.
	 *
	 * @param location the current location of the guest
	 * @param type the type of the guest
	 * @param happiness the current happiness of the guest
	 */
	reflex atLocation when: target.location = location {

		switch (location) {
			match one_of(Bar).location {
				if (type = "Party") {
					happines <- min(1, happines + 0.01);
				} else if (type = "Introvert") {
					happines <- max(0, happines - 0.01);
				} else if (type = "Bar-Hoppers") {
					happines <- min(1, happines + 0.02);
				} else if (type = "Socialite") {
					happines <- min(1, happines + 0.01);
				} else if (type = "Stooner") {
					happines <- min(1, happines + 0.01);
				}
			}
			match one_of(Club).location {
				if (type = "Party") {
					happines <- min(1, happines + 0.02);
				} else if (type = "Introvert") {
					happines <- max(0, happines - 0.02);
				} else if (type = "Bar-Hoppers") {
					happines <- min(1, happines + 0.01);
				} else if (type = "Socialite") {
					happines <- min(1, happines + 0.02);
				} else if (type = "Stooner") {
					happines <- max(0, happines - 0.01);	
				}
			}
			match one_of(Cafe).location {
				if (type = "Party") {
					happines <- max(0, happines - 0.01);			
				} else if (type = "Introvert") {
					happines <- min(0, happines + 0.01);			
				} else if (type = "Bar-Hoppers") {
					happines <- max(0, happines - 0.01);		
				} else if (type = "Socialite") {
					happines <- min(0, happines + 0.01);	
				} else if (type = "Stooner") {
					happines <- min(0, happines + 0.01);		
				}
			}
		}
	}


	/**
	* This reflex responds to a request to start a conversation by calculating the likelihood of the current guest accepting the conversation and either accepting or declining the request. If the conversation is accepted, the current guest's conversation partner is set to the sender of the request.
	* @param informs A list of messages to be processed.
	* @param inConversation A boolean value indicating whether the current guest is in a conversation.
	* @param guest The current guest's conversation partner.
	* @param name The name of the current guest.
	*/
	reflex responding_to_startconversation when: !empty(proposes) and !inConversation {
		loop proposeMsg over: proposes {  // Retrieve the sender's attributes and type from the message contents
		  // Checks if the guest is currently in a conversation
		  if (guest != nil) {
			  write name + " declines conversation with " + guest.name + "(Busy talking to someone else)";
			  do reject_proposal message:proposeMsg contents: ['refuse'];
		  } else {
  			  string sender_name <- proposeMsg.contents[0];
			  string sender_type <- proposeMsg.contents[1];
			  float sender_friendliness <- proposeMsg.contents[2];
			  float sender_confidence <- proposeMsg.contents[3];
			  float sender_openminded <- proposeMsg.contents[4];
			  
			  // Use a utility function to calculate the likelihood of the guest accepting the conversation
			  //float accept_probability <- calculate_conversation_acceptance_probability(sender_friendliness, sender_confidence, sender_openminded, sender_type);
			  float accept_probability <- 0.6;
			  
			  // If the probability is above a certain threshold, accept the conversation
			  if (accept_probability > 0.5) {
			    write sender_name + " starts a conversation with " + name;
			    do accept_proposal message:proposeMsg contents: ['agree'];
				inConversation <- true;
			    // Set the person variable to the sender to indicate that a conversation has started
			    guest <- proposeMsg.sender;
			  } else {
			    write name + " declines conversation with " + sender_name;
			    do reject_proposal message:proposeMsg contents: ['refuse'];
			    do remember(guest);
			  }
		  }
		}
	}
	
	/**
	* This method adds a guest to the current guest's memory with a 60% chance. If the current guest's memory is full, the oldest guest in the memory is removed to make space for the new guest.
	* @param guest The guest to be added to the current guest's memory.
	*/
	action remember (Guest guest) {
		
	    bool remeber <- flip(0.6);
		if (remeber) {
			if(length(smallbrain) < 2) {
				smallbrain <+ target;
			} else {
				remove item:smallbrain[0] from:smallbrain;
				smallbrain <+ target;
			}
		}

		guest <- nil;
	}
	
	/**
	* This reflex responds to a conversation by ending it if the sender refuses to continue the conversation. The sender is also added to the current guest's memory with a 60% chance.
	* @param informs A list of messages to be processed.
	* @param inConversation A boolean value indicating whether the current guest is in a conversation.
	*/
	reflex responding_to_conversation when: !empty(reject_proposals) and inConversation {
		loop rejectMsg over: reject_proposals {  // Retrieve the sender's attributes and type from the message contents
	 		inConversation <- false;
	 		do remember(guest);
		}
	}
	
	/**
	* This reflex is triggered when the guest receives an 'End_Conversation' message.
	* If the message is received, the guest will end the conversation and remember the sender.
	* @param informs a list of received inform messages
	*/
	reflex end_conversation when: !empty(informs) {
		// Iterate through the list of received inform messages
		loop informMsg over: informs {
			// If the message is an 'End_Conversation' message, end the conversation
			if (informMsg.contents[0] = "End_Conversation") {
			 		inConversation <- false;
			 		write name + " ends conversation with " + informMsg.sender;
			 		do remember(guest);
	 		}
 		}
	}	
	
	/**
	 * Calculates the probability that a guest will accept a conversation with another guest based on their individual traits and types.
	 * @param sender_friendliness The friendliness of the guest initiating the conversation.
	 * @param sender_aggressiveness The aggressiveness of the guest initiating the conversation.
	 * @param sender_assertiveness The assertiveness of the guest initiating the conversation.
	 * @param sender_type The type of the guest initiating the conversation.
	 * @return The probability that the conversation will be accepted, a value between 0 and 1.
	*/
    float calculate_conversation_acceptance_probability(float sender_friendliness, float sender_confidence, float sender_openminded, string sender_type) {
	 	float acceptanceProbability <- 0.5;
	 	
		// Adjust the probability based on the sender's and receiver's friendliness
		acceptanceProbability <- acceptanceProbability + ((sender_friendliness - 0.5) / 5);
		acceptanceProbability <- acceptanceProbability + ((friendliness - 0.5) / 5);	 	
	 
	 	// Adjust the probability based on the sender's and receiver's assertiveness
	    acceptanceProbability <- acceptanceProbability + ((sender_openminded - 0.5) / 5);
	    acceptanceProbability <- acceptanceProbability - ((open_minded - 0.5) / 5);
		
		// Adjust the probability based on the sender's and receiver's type
		if (sender_type = "Party") {
		    acceptanceProbability <- acceptanceProbability + 0.1;
		} else if (sender_type = "Introvert") {
			acceptanceProbability <- acceptanceProbability - 0.1;
		} else if (sender_type = "Bar-Hoppers") {
			acceptanceProbability <- acceptanceProbability + 0.1;
		} else if (sender_type = "Socialite") {
			acceptanceProbability <- acceptanceProbability + 0.2;
		} else if (sender_type = "Stooner") {
			acceptanceProbability <- acceptanceProbability - 0.1;
		}
		
		if (type = "Party") {
		   	acceptanceProbability <- acceptanceProbability + 0.1;
		} else if (type = "Introvert") {
		    acceptanceProbability <- acceptanceProbability - 0.1;
		} else if (type = "Bar-Hoppers") {
			acceptanceProbability <- acceptanceProbability + 0.0;
		} else if (type = "Socialite") {
			acceptanceProbability <- acceptanceProbability + 0.2;
		} else if (type = "Stooner") {
			acceptanceProbability <- acceptanceProbability + 0.2;
		}
		 	
	  // Make sure the probability is within the range of 0 and 1
	  acceptanceProbability <- min(1, max(0, acceptanceProbability));
	
	  return acceptanceProbability;
	}

	/**
	* This reflex starts a conversation with a nearby guest if the current guest's confidence is high enough based on their type.
	* @param Guest at_distance A list of guests within a distance of 1 from the current guest.
	* @param guest The current guest's conversation partner.
	* @param type The type of the current guest.
	* @param confidence The confidence of the current guest.
	*/
	reflex starts_conversation when: !(empty(Guest at_distance 2)) and guest = nil and target.location = location {
	    if (type = "Party" and confidence > 0.5) {
	      do find_person_to_talk_to;
	    } else if (type = "Introvert" and confidence > 0.75) {
	      do find_person_to_talk_to;
	    } else if (type = "Bar-Hoppers" and confidence > 0.5) {
	      do find_person_to_talk_to;
	    } else if (type = "Socialite" and confidence > 0.9) {
	      do find_person_to_talk_to;
	    } else if (type = "Stooner" and confidence > 0.5) {
	      do find_person_to_talk_to;
	    }
	}
	
	/**
	* This action finds a guest to start a conversation with from a list of guests within a distance of 2. If a suitable guest is found, the current guest starts a conversation with them.
	* @param at_distance A list of guests within a distance of 2 from the current guest.
	* @param smallbrain The memory of the current guest.
	* @param guest The current guest's conversation partner.
	*/  
	action find_person_to_talk_to {
		loop g over: Guest at_distance 2 {
			if (!(smallbrain contains g)) {
				write name + " tries to talk to " + g;
				guest <- g;
				inConversation <- true;
				do start_conversation to: [guest] protocol: 'fipa-contract-net' performative: 'propose' contents: [name, type,friendliness, confidence, open_minded];
				return;
			}
		}
	}
 
	/**
	* The inConversation reflex is triggered when the inConversation flag is set to true.
	* It is used to end the conversation between the guest and another guest and adjust the happiness of the guest based on the similarity between the two guests.
	* @param person The other guest in the conversation.
	* @param happines The happiness of the guest.
	* @param type The type of the guest.
	*/
	reflex inConversation when: inConversation {
		int rand <- rnd(50,100);
		
		// End the conversation if the guest's happiness is below 0.2 or at a random time
		if (happines < 0.2 or time mod rand = 0 ) {
			//write name + " ends conversation with " +guest;
			do start_conversation to: [guest] protocol: 'fipa-contract-net' performative: 'inform' contents: ['End_Conversation'];
			inConversation <- false;
	 		do remember(guest);
		} 
		
		// Calculate the similarity between the two guests
		float similarity <- calculate_similarity(guest.friendliness, guest.confidence, guest.open_minded, guest.type);
		
		// Adjust the happiness of the guest based on the similarity and the guest's type
        if (type = "Party" and similarity > 0.87) {
            happines <- min(1, happines + 0.25);
        } else if (type = "Introvert" and similarity > 0.91) {
            happines <- min(1, happines + 0.25);
        } else if (type = "Bar-Hoppers" and similarity > 0.85) {
            happines <- min(1, happines + 0.25);
        } else if (type = "Socialite" and similarity > 0.80) {
            happines <- min(1, happines + 0.25);
        } else if (type = "Stooner" and similarity > 0.75) {
            happines <- min(1, happines + 0.25);
        } else {
            happines <- max(0, happines - 0.25);
        }   	
	}
	
	/**
	* Calculates the similarity between two guests based on their personality traits and types.
	* @param sender_friendliness the friendliness of the sender
	* @param sender_confidence the confidence of the sender
	* @param sender_openminded the open-mindedness of the sender
	* @param senderType the type of the sender
	* @return a value between 0 and 1 indicating the similarity between the sender and the receiver, with 1 being the most similar
	*/
	float calculate_similarity(float sender_friendliness, float sender_confidence, float sender_openminded, string senderType) {
  		float similarity <- 0.0;
  		
	  	// Calculate the difference between the sender's and receiver's friendliness, confidence and open-mindedness
		float friendlinessDifference <- abs(sender_friendliness - friendliness);
		float confidenceDifference <- abs(sender_confidence - confidence);
		float openmindednessDifference <- abs(sender_openminded - open_minded);		
  
		// Adjust the similarity based on the difference in friendliness, confidence and open-mindedness
		similarity <- similarity + ((1 - friendlinessDifference) / 2);
		similarity <- similarity + ((1 - confidenceDifference) / 2);
		similarity <- similarity + ((1 - openmindednessDifference) / 2);
		
		// Adjust the similarity based on the guest's types
		if (senderType = type) {
			similarity <- similarity + 0.5;
		}
		
		// Make sure the similarity is within the range of 0 and 1
		similarity <- min(1, max(0, similarity));
		
		return similarity;
  	}

	rgb color <- nil;
	/**
	 * Draws a triangle with a specific color based on the type of a guest.
	 * @param type the type of the guest
	 */
 	aspect base {
		if (type = "Party") {
			color <- "cyan";
			draw triangle(3) color: color;		
		} else if (type = "Introvert") {
			color <- "red";
			draw triangle(3) color: color;		
		} else if (type = "Bar-Hoppers") {
			color <- "blue";
			draw triangle(3) color: color;		
		} else if (type = "Socialite") {
			color <- "gold";
			draw triangle(3) color: color;	
		} else if (type = "Stooner") {
			color <- "black";
			draw triangle(3) color: color;		
		}
	}	
}

/**
 * Represents the parent species to all locations.
 */
species Location {}

/**
 * Represents a bar location.
 */
species Bar parent: Location {
  /**
   * Draws a square with a brown color.
   */
 	aspect base {
		draw square(3) color: rgb("brown");
	}	
}

/**
 * Represents a club location.
 */
species Club parent: Location {
  /**
   * Draws a square with a pink color.
   */
 	aspect base {
		draw square(3) color: rgb("pink");
	}	
}

/**
 * Represents a cafe location.
 */
species Cafe parent: Location {
  /**
   * Draws a square with a black color.
   */	
 	aspect base {
		draw square(3) color: rgb("black");
	}	
}


experiment FinalProject type:gui {
	output {
		display myDisplay {
			species Guest aspect:base;
			species Bar aspect:base;
			species Club aspect:base;
			species Cafe aspect:base;			
		}


		display chart {
        	chart "Happiness" type: series style: spline {
        		data "Avg Happiness" value: (Guest mean_of each.happines) color:#black accumulate_values: true line_visible:true;
                //datalist Guest collect each.type value: (Guest collect each.happines) accumulate_values: true line_visible:true;
                //datalist Guest collect each.name value: (Guest collect each.happines) color: (Guest collect each.color) accumulate_values: true line_visible:true;
        	}
    	}
	}
}