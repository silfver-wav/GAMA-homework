/**
* Name: Task2
* Based on the internal empty template. 
* Author: linus and victor
* Tags: 
*/


model Task2

/* Insert your model definition here */

global {
    int numberOfGuests <- 10;
	int numberOfStages <- 4;
	// int numberOfActs <- 6;
	
	init {
		create Guest number:numberOfGuests;
		create Leader number:1;
		
		loop counter from: 1 to: numberOfGuests {
			Guest my_agent <- Guest[counter - 1];
			my_agent <- my_agent.setName(counter);
		}	
    	
		create Stage number: 1
		{
			location <- {25, 25};
		}

		
		create Stage number: 1
		{
			location <- {75,25};
		}

		
		create Stage number: 1
		{
			location <- {25, 75};
		}
		create Stage number: 1
		{
			location <- {75, 75};
		}

		
		loop counter from: 1 to: numberOfStages {
			Stage my_agent <- Stage[counter - 1];
			my_agent <- my_agent.setName(counter);
    	}	

	}
}

species Leader skills:[fipa]{

	list<int> nrOfGuestsAtStage <- [0,0,0,0];
	
	reflex getGuestsTargets when: (!empty(informs))
	{
		loop i over: informs
		{
			if (i.contents[0] = 'Stage0') {
				nrOfGuestsAtStage[0] <- nrOfGuestsAtStage[0] + 1;
			} else if (i.contents[0] = 'Stage1') {
				nrOfGuestsAtStage[1] <- nrOfGuestsAtStage[1] + 1;
			} else if (i.contents[0] = 'Stage2') {
				nrOfGuestsAtStage[2] <- nrOfGuestsAtStage[2] + 1;
			} else if (i.contents[0] = 'Stage3') {
				nrOfGuestsAtStage[3] <- nrOfGuestsAtStage[3] + 1;
			}
			do end_conversation message:i contents: ['End!'];									
		}
		write 'here';
		do start_conversation with: (to: list(Guest), protocol: 'no-protocol', performative: 'inform', contents: [nrOfGuestsAtStage]);
		nrOfGuestsAtStage <- [0,0,0,0];
	}

	
}

species Guest skills:[moving, fipa] {
	float utility <- 0.0;
	float maxUtility <- 0.0;
	float size <- rnd(0.1,1.0);
	float lightshow <- rnd(0.1,1.0);
	float speakers <- rnd(0.1,1.0);
	float avgbpm <- rnd(0.0,1.0);
	float acoustic <- rnd(0.1,1.0);
	float electronic <- rnd(0.1,1.0);
	
	Stage target <- nil;
	bool joinedAct <- false;
	float crowdMass <- rnd(0.1,1.0);
	bool toldLeader <- false;
	
	list<float> utilities <- [];
	
	string guestName <- "Undefined";
	list<Stage> stages <- (Stage at_distance 1000);
	
	action setName(int num) {
		guestName <- "Person " + num;
	}
	
	reflex move
	{
		if (target != nil) {
			do goto target:target.location;
			speed <- 2.5;
		}
		else {
			do wander;
		}
	}
	
	reflex getAnnoucement when: !empty(informs) and !joinedAct {
		loop i over: informs {
			utility <- size*float(i.contents[0]) + lightshow*float(i.contents[1]) + speakers*float(i.contents[2]) + 
				avgbpm*float(i.contents[3]) + acoustic*float(i.contents[4]) + electronic*float(i.contents[5]);
			write '(Time ' + time + '): ' + 'utility for ' + agent(i.sender).name + ' ' +utility+ ' for guest ' +guestName;	
			if (utility > maxUtility) {
				target <- i.sender;
				maxUtility <- utility;
				joinedAct <- true;
			}
			do end_conversation message:i contents: ['End!'];
			utilities <+ utility;
		}
		write name + ' is going to ' + target.name + 'that has the highest utility: ' +maxUtility;
		write '';
	}
/*	
	reflex tellWhereImGoing when: joinedAct and !toldLeader{
		do start_conversation (to: [one_of(Leader)], protocol: 'no-protocol', performative: 'inform', contents: [target]);
		toldLeader <- true;
	}
	
	reflex getMassUtility when: !empty(informs) and  joinedAct {
		message informMsg <- informs at 0;
		do end_conversation message:informMsg contents: ['End!'];	
		int count <- 0;
		list<int> stages <- informMsg.contents[0];
		if (target.name = 'Stage0') {
			count <- stages[0];
		} else if (target.name = 'Stage1') {
			stages[1] <- stages[1];
		} else if (target.name = 'Stage2') {
			stages[2] <- stages[2];
		} else if (target.name = 'Stage3') {
			stages[3] <- stages[3];
		}
		
		bool flag <- false;
		float stageMass <- float(count/numberOfGuests);
		int i <- 0;
		loop u over: utilities {
			if ((u + crowdMass*stageMass) > maxUtility) {
				write name + ' new max utility ' + utility;
				target <- stages[i];
				maxUtility <- utility;
				flag <- true;				
			}
			i <- i + 1;
		}
		if (flag) {
			write name + ' is chaning becuase of crowd mass and going to ' + target.name + 'that has the highest utility: ' +maxUtility;				
		}		
	}
	
*/	
	reflex leaveStage when: (time mod 65 = 45) and joinedAct {
		write name + 'left the stage';
		target <- nil;
		joinedAct <- false;
		utility <- float(0);
		maxUtility <- float(0);
		toldLeader <- false;
	}
	
	aspect default
	{
		draw circle (1) at: location color: #black; 
	}
}

species Stage skills:[fipa] {
	float sizeStage <- rnd(0.1,1.0);
	float lightshowStage <- rnd(0.1,1.0);
	float speakersStage <- rnd(0.1,1.0);
	float avgbpmStage <- rnd(0.0,1.0);
	float acousticStage <- rnd(0.1,1.0);
	float electronicStage <- rnd(0.1,1.0);
	bool actStarted <- false;

	string stageName <- "Undefined";
	
	action setName(int num) {
		stageName <- "Stage " + num;
	}
	
	reflex annouceAct when: !actStarted and ((time mod 45) = 1) {
		//write 'acts ' + acts;
		sizeStage <- rnd(0.1,1.0);
		lightshowStage <- rnd(0.1,1.0);
		speakersStage <- rnd(0.1,1.0);
		avgbpmStage <- rnd(0.0,1.0);
	 	acousticStage <- rnd(0.1,1.0);
		electronicStage <- rnd(0.1,1.0);
		write '(Time ' + time + '): ' + stageName + ' annouces act';	
		do start_conversation (to: list(Guest), protocol: 'no-protocol', performative: 'inform', 
			contents: [sizeStage, lightshowStage, speakersStage,avgbpmStage, acousticStage, electronicStage]
		);
		actStarted <- true;
	}
	
	
	reflex endAct when: actStarted and ((time mod 65) = 45) {
		actStarted <- false;
	}
	
	
	
	aspect default
	{
		draw square(5) at: location color: #blue; 
	}
}

experiment task2 type: gui {
	output {
		display map type: opengl 
		{
			species Guest;
			species Stage;		
		}
	}
}