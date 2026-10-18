/* Reel or Real? - round bank (39 rounds)
 *
 * Every round starts as status "draft". Real rounds were written from memory:
 * fact-check each against its `sources` BEFORE the event, then set
 * status: "approved" (the staff panel counts how many are still draft).
 *
 * policy_reference: the policy shown big on the answer screen, e.g.
 * "Acceptable Use Policy, section 4". null = config.js defaultPolicy / placeholder.
 *
 * enabled:false rounds are never served (R16 needs comms clearance first;
 * R18 and R26 are physical-security cases, turned off because the booth is cyber-only).
 * audience:["technical"] rounds are skipped by the booth unless
 * CONFIG.includeTechnical is true.
 * Values that start with "[" (placeholders) are never shown on screen.
 */
window.ROUNDS = [
  {
    "id": "R01",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Forgotten Doorway",
    "answer": "REEL",
    "difficulty": "easy",
    "audience": [
      "all"
    ],
    "themes": [
      "authentication",
      "privileged-access"
    ],
    "clue": "Secret password",
    "evidence": [
      "A curious teenager finds a way into a secret military computer.",
      "He only wants to explore and play games, not cause harm.",
      "He gets in using a hidden password the system's creator left behind.",
      "The computer starts acting on its own, and things quickly get out of hand."
    ],
    "reveal_title": "WarGames",
    "year": 1983,
    "weakness": "A secret \"backdoor\" password was left in place and gave full access.",
    "control_theme": "Strong passwords, no backdoors",
    "control_shield": "Use unique accounts, strong authentication, controlled privileged access and remove backdoors.",
    "what_you_can_do": "Never share or reuse passwords, and report any system with a secret shortcut or default login.",
    "takeaway": "A password can be a plot twist.",
    "discussion_question": "Where might a forgotten shortcut or default login still exist in a system you use?",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R04",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Universal Key",
    "answer": "REEL",
    "difficulty": "medium",
    "audience": [
      "all"
    ],
    "themes": [
      "privileged-access",
      "segregation-of-duties"
    ],
    "clue": "Master key",
    "evidence": [
      "A team of security testers is hired to steal a small black box.",
      "The box can unlock almost any protected computer system.",
      "Several groups chase it, because it could open banks, power grids and more.",
      "One powerful tool turns out to be more dangerous than any single password."
    ],
    "reveal_title": "Sneakers",
    "year": 1992,
    "weakness": "One all-powerful tool meant a single mistake could open everything.",
    "control_theme": "Only the access you need",
    "control_shield": "Apply least privilege, segregation of duties and controlled privileged access.",
    "what_you_can_do": "Don't share admin accounts, and only use special access when you actually need it.",
    "takeaway": "Some keys should never be universal.",
    "discussion_question": "Which single account or tool in our work could cause the most damage if misused?",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R06",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Trusted Employee",
    "answer": "REEL",
    "difficulty": "easy",
    "audience": [
      "all"
    ],
    "themes": [
      "insider",
      "privileged-access"
    ],
    "clue": "Under pressure",
    "evidence": [
      "Criminals can't break through a bank's strong computer security.",
      "So they take a trusted employee's family hostage instead.",
      "They force him to use his own access to move money for them.",
      "The attack works by pressuring a person, not by beating the technology."
    ],
    "reveal_title": "Firewall",
    "year": 2006,
    "weakness": "A trusted employee's real access was misused under pressure.",
    "control_theme": "Speak up about pressure",
    "control_shield": "Apply least privilege, need-to-use access and individual accountability.",
    "what_you_can_do": "If anyone pressures you to share access or skip a security step, report it to your security team, whatever the reason.",
    "takeaway": "The weakest link was not a cable.",
    "discussion_question": "How would a colleague under personal pressure be able to raise the alarm safely?",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R08",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Visitor on the Network",
    "answer": "REEL",
    "difficulty": "medium",
    "audience": [
      "all",
      "technical"
    ],
    "themes": [
      "segmentation",
      "supply-chain"
    ],
    "clue": "Plugged in",
    "evidence": [
      "A spy agency captures a villain's laptop.",
      "Back at headquarters, they plug it into their own network to look inside.",
      "Hidden software on the laptop opens the agency up to the villain.",
      "The agency is breached from the inside."
    ],
    "reveal_title": "Skyfall",
    "year": 2012,
    "weakness": "An untrusted device was plugged straight into a trusted network.",
    "control_theme": "Don't plug in unknown devices",
    "control_shield": "Analyse untrusted devices in isolated environments, control what may connect to the network, and monitor for unexpected behaviour.",
    "what_you_can_do": "Never plug unknown USB drives or devices into work equipment. Hand them to IT.",
    "takeaway": "Not every guest should get a network port.",
    "discussion_question": "What would you do if you found a USB drive in the car park or lift?",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R17",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Only Administrator",
    "answer": "REEL",
    "difficulty": "medium",
    "audience": [
      "all",
      "technical"
    ],
    "themes": [
      "segregation-of-duties",
      "insider"
    ],
    "clue": "One person in charge",
    "evidence": [
      "Only one worker really knows how the park's computer system works.",
      "He is unhappy with his pay and agrees to sell secrets to a rival.",
      "He switches off the security systems so he can sneak out with them.",
      "The shutdown causes far more chaos than he ever planned."
    ],
    "reveal_title": "Jurassic Park",
    "year": 1993,
    "weakness": "One person had total control and nobody was checking.",
    "control_theme": "Shared control and checks",
    "control_shield": "Segregate duties, require peer review and two-person approval for critical changes, and monitor privileged activity.",
    "what_you_can_do": "If you have admin access, expect it to be logged and checked. That protects you too.",
    "takeaway": "One person should never hold every key.",
    "discussion_question": "If our only expert on a system left tomorrow, what would break and who else could step in?",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R18",
    "enabled": false,
    "status": "draft",
    "mystery_title": "The Vault Room",
    "answer": "REEL",
    "difficulty": "easy",
    "audience": [
      "all"
    ],
    "themes": [
      "physical-security",
      "social-engineering"
    ],
    "clue": "Break-in",
    "evidence": [
      "A team plans to steal secret files from a computer in a heavily guarded room.",
      "The room has alarms for sound, heat and even the weight of a footstep.",
      "The plan relies on knowing the staff's routines and using fake identities.",
      "The computer is well protected, but the people and doors around it are not."
    ],
    "reveal_title": "Mission: Impossible",
    "year": 1996,
    "weakness": "Strong technology was beaten by fake identities and getting physically inside.",
    "control_theme": "Building and visitor security",
    "control_shield": "Combine physical access checks, visitor escorting, clean-desk rules and monitored sensitive areas with staff awareness.",
    "what_you_can_do": "Politely challenge or report people without a badge, and don't hold the door for strangers.",
    "takeaway": "The strongest vault still has a door.",
    "discussion_question": "When did you last see someone enter our office without a badge, and what did you do?",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R19",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Night Desk",
    "answer": "REEL",
    "difficulty": "easy",
    "audience": [
      "all"
    ],
    "themes": [
      "social-engineering",
      "vishing"
    ],
    "clue": "Phone call",
    "evidence": [
      "A teenager phones a TV station's night guard, pretending to be a staff member.",
      "He says he lost a phone number he needs to connect to the computer.",
      "The guard reads it out without checking who is calling.",
      "That number becomes the way into the station's computer system."
    ],
    "reveal_title": "Hackers",
    "year": 1995,
    "weakness": "A staff member gave away access details to a caller they hadn't checked.",
    "control_theme": "Check who you're talking to",
    "control_shield": "Verify identity before sharing access information, publish a clear verification procedure, and train all staff including reception and shift teams.",
    "what_you_can_do": "Never give out access details on a call you didn't make. Hang up and call back on a number you know.",
    "takeaway": "Confidence on the phone is not proof.",
    "discussion_question": "What is our official way to confirm that a caller really is who they say?",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R20",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Person Who Never Was",
    "answer": "REEL",
    "difficulty": "hard",
    "audience": [
      "all"
    ],
    "themes": [
      "data-integrity",
      "identity"
    ],
    "clue": "Erased identity",
    "evidence": [
      "A woman discovers a secret flaw in popular security software.",
      "The criminals who made the software have hidden a way in.",
      "They use it to change her records in many computer systems.",
      "Because every record agrees, no one believes she is who she says she is."
    ],
    "reveal_title": "The Net",
    "year": 1995,
    "weakness": "A hidden backdoor in trusted software let someone rewrite a person's records.",
    "control_theme": "Trusted software, accurate records",
    "control_shield": "Vet and review security products, avoid undocumented access paths, and protect records with change logs and independent verification.",
    "what_you_can_do": "Check your own accounts and records regularly, and report any changes you didn't make.",
    "takeaway": "If every record agrees, check who wrote them.",
    "discussion_question": "How would we detect and correct a record that was changed without authorisation?",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R21",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Domino Day",
    "answer": "REEL",
    "difficulty": "medium",
    "audience": [
      "all"
    ],
    "themes": [
      "resilience",
      "segmentation",
      "incident-response"
    ],
    "clue": "Chain reaction",
    "evidence": [
      "Attackers shut down a country's traffic lights, power and banks, one after another.",
      "The attacker used to work on these systems and knows how they connect.",
      "Emergency teams struggle because their own systems are down too.",
      "The chaos hides an even bigger plan to steal money."
    ],
    "reveal_title": "Live Free or Die Hard",
    "year": 2007,
    "weakness": "Connected systems with no backup plan let one attack spread everywhere.",
    "control_theme": "Have a backup plan",
    "control_shield": "Segment critical systems, rehearse incident response and business continuity, and review dependencies and manual fallbacks.",
    "what_you_can_do": "Know your team's backup plan if a key system goes down, and join practice drills when invited.",
    "takeaway": "Plan for the day the dominoes fall.",
    "discussion_question": "If our most important system was down for a day, what would we do first?",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R22",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Plant That Failed",
    "answer": "REEL",
    "difficulty": "hard",
    "audience": [
      "technical"
    ],
    "themes": [
      "ics-ot",
      "segmentation"
    ],
    "clue": "Plant attack",
    "evidence": [
      "Harmful software gets into the control system of a power plant.",
      "The attackers use it to change how the machines run.",
      "Equipment overheats and is destroyed.",
      "Investigators struggle to find out who did it."
    ],
    "reveal_title": "Blackhat",
    "year": 2015,
    "weakness": "Office computers and plant control systems were not kept apart.",
    "control_theme": "Keep control systems separate",
    "control_shield": "Separate IT and operational networks, restrict remote access, control removable media and email into OT zones, and monitor for unexpected changes.",
    "what_you_can_do": "Never connect personal devices to work equipment, and report anything unusual.",
    "takeaway": "A digital mistake can become a physical one.",
    "discussion_question": "Which of our systems could cause real-world harm if tampered with?",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R23",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Searchable Citizen",
    "answer": "REEL",
    "difficulty": "medium",
    "audience": [
      "all"
    ],
    "themes": [
      "privacy",
      "insider",
      "data-protection"
    ],
    "clue": "Snooping",
    "evidence": [
      "A government official can search people's phone calls and locations.",
      "He uses this power to cover up his own crime, not for his job.",
      "An ordinary lawyer is tracked everywhere after unknowingly getting secret evidence.",
      "Nobody is checking how the snooping power is used."
    ],
    "reveal_title": "Enemy of the State",
    "year": 1998,
    "weakness": "Powerful access to personal data was misused, and no one was checking.",
    "control_theme": "Use data only for your job",
    "control_shield": "Apply purpose limitation, log and review access to sensitive data, and require approvals for bulk searches.",
    "what_you_can_do": "Only look at customer or colleague data you need for your task. Access can be logged and checked.",
    "takeaway": "Access is not the same as permission.",
    "discussion_question": "Who reviews how we use the personal data we can see in our daily work?",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R24",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Quiet Transfer",
    "answer": "REEL",
    "difficulty": "medium",
    "audience": [
      "all"
    ],
    "themes": [
      "financial-fraud",
      "detection-escalation"
    ],
    "clue": "Money trail",
    "evidence": [
      "A top hacker is pressured into writing a program to steal billions.",
      "The program moves the money in small, quiet steps.",
      "Each step looks normal on its own.",
      "The plan only works if nobody looks at the bigger picture."
    ],
    "reveal_title": "Swordfish",
    "year": 2001,
    "weakness": "Nobody was watching for unusual patterns in money movements.",
    "control_theme": "Check unusual payments",
    "control_shield": "Monitor for unusual transaction patterns, require dual approval for large transfers, and review privileged changes to payment systems.",
    "what_you_can_do": "If a payment or request looks unusual, check with someone before acting, even if it seems routine.",
    "takeaway": "Look at the pattern, not just the payment.",
    "discussion_question": "Which of our routine approvals would an attacker try to blend into?",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R02",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Silent Foothold",
    "answer": "REAL",
    "difficulty": "medium",
    "audience": [
      "all"
    ],
    "themes": [
      "third-party",
      "segmentation"
    ],
    "clue": "Supplier",
    "evidence": [
      "A big store chain lets an outside supplier log into its network.",
      "Criminals hack the supplier instead of the store chain.",
      "They use the supplier's login to get inside.",
      "From there, they reach the systems that handle customer card payments."
    ],
    "reveal_title": "Target breach",
    "year": 2013,
    "weakness": "A supplier's login was the way in, and nothing stopped the hackers going further.",
    "control_theme": "Limit supplier access",
    "control_shield": "Require supplier security controls, least privilege and network segmentation.",
    "what_you_can_do": "If you manage a supplier, give them only the access they need, and remove it when the work is done.",
    "takeaway": "The front door was somewhere else.",
    "discussion_question": "Who outside our organisation can reach our systems, and who reviews that?",
    "policy_reference": null,
    "sources": [
      "US Senate Committee on Commerce, Science, and Transportation, 'A \"Kill Chain\" Analysis of the 2013 Target Data Breach' (2014)"
    ],
    "sensitivity": "named-company"
  },
  {
    "id": "R03",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Code That Would Not Open",
    "answer": "REAL",
    "difficulty": "easy",
    "audience": [
      "all"
    ],
    "themes": [
      "patching",
      "resilience"
    ],
    "clue": "Files locked",
    "evidence": [
      "Many computers have missed important software updates.",
      "Suddenly, files are locked and a ransom is demanded.",
      "It spreads from computer to computer by itself, without anyone clicking anything.",
      "Hospitals cancel appointments and staff go back to pen and paper."
    ],
    "reveal_title": "WannaCry attack on UK hospitals (NHS)",
    "year": 2017,
    "weakness": "Old, un-updated computers let the attack spread fast.",
    "control_theme": "Keep software updated",
    "control_shield": "Identify, prioritise and remediate vulnerabilities within risk-based timelines.",
    "what_you_can_do": "Install updates promptly, don't keep putting off restarts, and report devices that can't be updated.",
    "takeaway": "Update before a known weakness becomes a crisis.",
    "discussion_question": "What happens to a device you own that can't be updated any more?",
    "policy_reference": null,
    "sources": [
      "UK National Audit Office, 'Investigation: WannaCry cyber attack and the NHS' (2018)",
      "Microsoft Security Bulletin MS17-010 (March 2017)"
    ],
    "sensitivity": "named-company"
  },
  {
    "id": "R05",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Missing Update",
    "answer": "REAL",
    "difficulty": "medium",
    "audience": [
      "all",
      "technical"
    ],
    "themes": [
      "patching",
      "vulnerability-management",
      "detection-escalation"
    ],
    "clue": "Missed update",
    "evidence": [
      "A serious flaw in website software is made public, along with a fix.",
      "The company has an update process, but one website is missed.",
      "Hackers use the flaw to steal the personal details of millions of people.",
      "The fix was already available before the attack began."
    ],
    "reveal_title": "Equifax breach",
    "year": 2017,
    "weakness": "A known flaw was left unfixed long enough for hackers to use it.",
    "control_theme": "Fix known flaws fast",
    "control_shield": "Define remediation windows and prioritise patching according to exposure and risk.",
    "what_you_can_do": "If you look after a system, know who updates it and act on update notices quickly.",
    "takeaway": "A known flaw still hurts if nobody fixes it.",
    "discussion_question": "How do we know every internet-facing system we run has been patched?",
    "policy_reference": null,
    "sources": [
      "US House Committee on Oversight and Government Reform, 'The Equifax Data Breach' (December 2018)",
      "US Government Accountability Office, GAO-18-559 (2018)"
    ],
    "sensitivity": "named-company"
  },
  {
    "id": "R07",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Remote Doorway",
    "answer": "REAL",
    "difficulty": "easy",
    "audience": [
      "all"
    ],
    "themes": [
      "mfa",
      "remote-access"
    ],
    "clue": "Password only",
    "evidence": [
      "Hackers get hold of an old password that still works.",
      "They use it to log in remotely, like an employee working from home.",
      "No second check, like a code sent to a phone, is needed.",
      "Once inside, their attack leads to a major fuel pipeline being shut down."
    ],
    "reveal_title": "Colonial Pipeline",
    "year": 2021,
    "weakness": "Logging in from outside needed only a password, with no second check.",
    "control_theme": "Use two-step verification",
    "control_shield": "Require approved remote-access services, multi-factor authentication and monitoring.",
    "what_you_can_do": "Turn on two-step verification wherever it's offered, and never reuse your work password.",
    "takeaway": "A correct password can still be the wrong person.",
    "discussion_question": "Which of our remote or legacy accounts might still rely on a password alone?",
    "policy_reference": null,
    "sources": [
      "Testimony of the CEO of Colonial Pipeline to the US Senate Committee on Homeland Security and Governmental Affairs (June 2021)"
    ],
    "sensitivity": "named-company"
  },
  {
    "id": "R09",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Warning Nobody Escalated",
    "answer": "REAL",
    "difficulty": "hard",
    "audience": [
      "all",
      "technical"
    ],
    "themes": [
      "detection-escalation",
      "privileged-access",
      "patching"
    ],
    "clue": "Ignored warning",
    "evidence": [
      "Hackers target a national healthcare database with records of over a million patients.",
      "They break into one computer, then slowly work their way towards the database.",
      "Staff notice warning signs, but they aren't reported quickly enough.",
      "The records of a top public figure are specifically targeted."
    ],
    "reveal_title": "SingHealth cyber attack (Singapore)",
    "year": 2018,
    "weakness": "Weakly protected admin accounts, missed updates and slow reporting let the attack run for weeks.",
    "control_theme": "Report early",
    "control_shield": "Harden and monitor privileged accounts, patch known vulnerabilities, and make escalating suspicious activity a rehearsed, no-blame habit.",
    "what_you_can_do": "If something seems off, like strange logins, unexpected pop-ups or slow systems, report it early. A false alarm costs minutes; a missed one can cost months.",
    "takeaway": "Report early; it's cheaper than reporting late.",
    "discussion_question": "What would make someone hesitate to report something suspicious here, and how do we remove that?",
    "policy_reference": null,
    "sources": [
      "Report of the Public Inquiry into the Cyber Attack on Singapore Health Services Private Limited Patient Database on or around 27 June 2018 (Committee of Inquiry, January 2019)"
    ],
    "sensitivity": "regional"
  },
  {
    "id": "R10",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Helpful Caller",
    "answer": "REAL",
    "difficulty": "easy",
    "audience": [
      "all"
    ],
    "themes": [
      "vishing",
      "social-engineering",
      "privileged-access"
    ],
    "clue": "Fake IT call",
    "evidence": [
      "Staff get phone calls from someone pretending to be from their own IT team.",
      "The caller sends them to a fake login page, and they type in their passwords.",
      "The attackers use internal tools to take over famous people's accounts.",
      "The accounts post a cryptocurrency scam to millions of followers."
    ],
    "reveal_title": "Twitter celebrity account hack",
    "year": 2020,
    "weakness": "Phone trickery gave attackers access to powerful internal tools.",
    "control_theme": "Check who's calling",
    "control_shield": "Verify callers through a trusted channel, use phishing-resistant MFA, and restrict and monitor internal admin tools.",
    "what_you_can_do": "If someone calls claiming to be IT, hang up and call back using the number in the staff directory.",
    "takeaway": "A friendly voice is not proof.",
    "discussion_question": "How would you check that a caller from 'IT' is genuine?",
    "policy_reference": null,
    "sources": [
      "New York State Department of Financial Services, 'Investigative Report on Twitter's July 2020 Bitcoin Hack' (October 2020)"
    ],
    "sensitivity": "named-company"
  },
  {
    "id": "R11",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Reset Request",
    "answer": "REAL",
    "difficulty": "medium",
    "audience": [
      "all",
      "technical"
    ],
    "themes": [
      "help-desk",
      "social-engineering",
      "identity"
    ],
    "clue": "Help desk",
    "evidence": [
      "An attacker finds an employee's details on a professional networking site.",
      "They call the IT help desk pretending to be that employee.",
      "The help desk resets the password without properly checking who it is.",
      "The attacker gets inside and later shuts down systems across hotels and casinos."
    ],
    "reveal_title": "MGM Resorts cyber attack",
    "year": 2023,
    "weakness": "The help desk didn't check identity properly before resetting a password.",
    "control_theme": "Check identity before resets",
    "control_shield": "Use strong identity verification for resets, especially for privileged users, with call-back or manager approval and monitoring of reset requests.",
    "what_you_can_do": "If you work at a help desk, check identity first. If you're a user, expect to be checked, and be glad when you are.",
    "takeaway": "The reset button is a master key.",
    "discussion_question": "What proof would our help desk ask for before resetting your account?",
    "policy_reference": null,
    "sources": [
      "MGM Resorts International, Form 8-K filed with the US SEC (September 2023)",
      "CISA and FBI joint advisory AA23-320A on Scattered Spider (November 2023)"
    ],
    "sensitivity": "named-company"
  },
  {
    "id": "R12",
    "enabled": true,
    "status": "draft",
    "mystery_title": "Fifty Prompts",
    "answer": "REAL",
    "difficulty": "easy",
    "audience": [
      "all"
    ],
    "themes": [
      "mfa",
      "social-engineering"
    ],
    "clue": "Too many pop-ups",
    "evidence": [
      "An attacker steals a contractor's username and password.",
      "They keep sending \"approve this login?\" requests to the contractor's phone.",
      "They also message the contractor pretending to be IT, asking them to accept.",
      "The contractor finally taps approve, and the attacker gets in."
    ],
    "reveal_title": "Uber breach",
    "year": 2022,
    "weakness": "Login approvals were worn down by repeated requests and pressure.",
    "control_theme": "Deny unexpected login requests",
    "control_shield": "Use number-matching or phishing-resistant MFA, limit prompt attempts, alert on repeated denials, and protect contractor access.",
    "what_you_can_do": "Never approve a login request you didn't start. Deny it and report it, even if someone tells you to accept.",
    "takeaway": "If you didn't ask for it, deny it.",
    "discussion_question": "What should you do if your phone buzzes with an MFA request at 2 a.m.?",
    "policy_reference": null,
    "sources": [
      "Uber, 'Security update' public statement (September 2022)"
    ],
    "sensitivity": "named-company"
  },
  {
    "id": "R13",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Boardroom Call",
    "answer": "REAL",
    "difficulty": "easy",
    "audience": [
      "all"
    ],
    "themes": [
      "deepfake",
      "payment-fraud",
      "social-engineering"
    ],
    "clue": "Video call",
    "evidence": [
      "A finance worker gets an urgent request from a senior boss to make secret payments.",
      "They join a video call with what look like several familiar colleagues.",
      "The faces and voices seem real, so the worker goes ahead.",
      "Millions are paid out before anyone realises the people on the call were fake."
    ],
    "reveal_title": "Arup deepfake video-call fraud (Hong Kong)",
    "year": 2024,
    "weakness": "AI-generated fake video and voices fooled the usual \"I recognise them\" check.",
    "control_theme": "Confirm payments another way",
    "control_shield": "Require out-of-band verification and multi-person approval for payments, however convincing the request seems.",
    "what_you_can_do": "Treat urgent payment requests as suspicious, even on video. Confirm another way, like calling a number you already know.",
    "takeaway": "Seeing is no longer believing.",
    "discussion_question": "What would we do if our CEO appeared on video and asked for an urgent, confidential transfer?",
    "policy_reference": null,
    "sources": [
      "Hong Kong Police public briefing on the case (early 2024)",
      "Arup public statement confirming it was the affected company (May 2024)"
    ],
    "sensitivity": "named-company"
  },
  {
    "id": "R14",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Trusted Update",
    "answer": "REAL",
    "difficulty": "hard",
    "audience": [
      "all",
      "technical"
    ],
    "themes": [
      "supply-chain",
      "detection-escalation"
    ],
    "clue": "Software update",
    "evidence": [
      "Thousands of organisations install a normal update for a popular IT tool.",
      "Hackers had secretly hidden harmful code inside the update.",
      "The trusted update lets them quietly spy on many organisations at once.",
      "Nobody notices for months, until a security company investigates its own break-in."
    ],
    "reveal_title": "SolarWinds supply-chain attack",
    "year": 2020,
    "weakness": "Hackers got into the software maker and slipped their code into a trusted update.",
    "control_theme": "Watch trusted software too",
    "control_shield": "Assess critical suppliers, monitor for unusual behaviour from trusted software, and limit the access and network reach of management tools.",
    "what_you_can_do": "Be wary of unexpected software installs, and report trusted tools behaving strangely.",
    "takeaway": "Trusted does not mean untouchable.",
    "discussion_question": "Which suppliers' software has the deepest access into our environment?",
    "policy_reference": null,
    "sources": [
      "US CISA Emergency Directive 21-01 (December 2020)",
      "SolarWinds Corporation, Form 8-K filed with the US SEC (December 2020)"
    ],
    "sensitivity": "named-company"
  },
  {
    "id": "R15",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Misplaced Permission",
    "answer": "REAL",
    "difficulty": "hard",
    "audience": [
      "technical"
    ],
    "themes": [
      "cloud-config",
      "least-privilege",
      "data-protection"
    ],
    "clue": "Online storage",
    "evidence": [
      "A company's website runs on rented online servers behind a badly set-up security filter.",
      "An outsider tricks the website into handing over temporary keys.",
      "The keys are used to copy files from the company's online storage.",
      "Personal details of a huge number of customers are taken."
    ],
    "reveal_title": "Capital One breach",
    "year": 2019,
    "weakness": "A setup mistake plus access that was far too wide exposed the stored data.",
    "control_theme": "Set up online systems safely",
    "control_shield": "Use secure configuration baselines, least-privilege cloud roles, automated misconfiguration scanning and monitoring of data access.",
    "what_you_can_do": "If you set up online systems, use approved settings and never give wider access \"just to make it work\".",
    "takeaway": "Small setup mistakes, big leaks.",
    "discussion_question": "Who checks the permissions on the cloud resources our team creates?",
    "policy_reference": null,
    "sources": [
      "US Department of Justice, Western District of Washington, press release and criminal complaint (July 2019)"
    ],
    "sensitivity": "named-company"
  },
  {
    "id": "R16",
    "enabled": false,
    "status": "draft",
    "mystery_title": "The Urgent Text",
    "answer": "REAL",
    "difficulty": "easy",
    "audience": [
      "all"
    ],
    "themes": [
      "phishing",
      "financial-fraud"
    ],
    "clue": "Bank text",
    "evidence": [
      "Customers get text messages that look like they come from their bank.",
      "The messages say there's an urgent problem and include a link.",
      "The link opens a fake login page that steals their details.",
      "Money disappears from their accounts within a short time."
    ],
    "reveal_title": "SMS phishing of OCBC customers (Singapore)",
    "year": 2021,
    "weakness": "A familiar sender name and a sense of urgency led people to type their details into a fake page.",
    "control_theme": "Spot scam texts",
    "control_shield": "Never use links in unsolicited messages; go to the official app or website directly; enable transaction limits and alerts; report scams.",
    "what_you_can_do": "Don't click links in unexpected texts. Type the address yourself or use the official app, and report scams via ScamShield.",
    "takeaway": "Urgency is the scammer's favourite tool.",
    "discussion_question": "What's the safest way to reach your bank when a message says there's a problem?",
    "policy_reference": null,
    "sources": [
      "Monetary Authority of Singapore and Singapore Police Force public statements on the December 2021 phishing scam (December 2021 - January 2022)",
      "MAS and The Association of Banks in Singapore joint statement on additional anti-scam measures (January 2022)"
    ],
    "sensitivity": "needs-clearance"
  },
  {
    "id": "R25",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Rounding Error",
    "answer": "REEL",
    "difficulty": "hard",
    "audience": [
      "all"
    ],
    "themes": [
      "financial-fraud",
      "change-control"
    ],
    "clue": "Tiny amounts",
    "evidence": [
      "Office workers secretly add a small program to their company's accounts system.",
      "It skims tiny fractions of a cent from every transaction.",
      "Each slice is too small for anyone to notice.",
      "A misplaced decimal point makes it take far too much, far too fast."
    ],
    "reveal_title": "Office Space",
    "year": 1999,
    "weakness": "Changes to the money system went live without anyone checking them.",
    "control_theme": "Question odd numbers",
    "control_shield": "Review and approve code changes before release, and reconcile accounts so small, repeated anomalies get flagged.",
    "what_you_can_do": "If numbers look slightly off again and again, report it. Small repeated oddities are worth a question.",
    "takeaway": "Small slices still add up.",
    "discussion_question": "",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R26",
    "enabled": false,
    "status": "draft",
    "mystery_title": "The Live Feed",
    "answer": "REEL",
    "difficulty": "easy",
    "audience": [
      "all"
    ],
    "themes": [
      "monitoring",
      "physical-security"
    ],
    "clue": "Security cameras",
    "evidence": [
      "Guards watch a casino vault on camera all night.",
      "What they see is actually a pre-recorded video.",
      "A sudden power cut gives the thieves a few minutes of cover.",
      "Nobody checks the vault in person until it's too late."
    ],
    "reveal_title": "Ocean's Eleven",
    "year": 2001,
    "weakness": "The guards trusted one camera feed without double-checking.",
    "control_theme": "Double-check what you see",
    "control_shield": "Protect camera and alarm feeds from tampering, and back them up with in-person checks and independent alerts.",
    "what_you_can_do": "If a screen, badge reader or alarm behaves oddly, tell security. Do not assume someone else has noticed.",
    "takeaway": "Seeing is not always believing.",
    "discussion_question": "",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R27",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Green Lights",
    "answer": "REEL",
    "difficulty": "hard",
    "audience": [
      "all"
    ],
    "themes": [
      "ics-ot",
      "resilience"
    ],
    "clue": "Traffic lights",
    "evidence": [
      "Thieves break into a city's traffic light computer.",
      "They change the lights to cause huge traffic jams downtown.",
      "Their own getaway route gets green lights all the way.",
      "Engineers struggle to take back control."
    ],
    "reveal_title": "The Italian Job",
    "year": 2003,
    "weakness": "An important city system could be changed remotely without strong protection.",
    "control_theme": "Protect important systems",
    "control_shield": "Separate control systems from office and internet networks, require strong authentication, and keep a tested manual fallback.",
    "what_you_can_do": "Never connect personal devices to equipment or control networks, and report unknown devices you see plugged in.",
    "takeaway": "Critical systems need a manual plan B.",
    "discussion_question": "",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R28",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Spinning Machines",
    "answer": "REAL",
    "difficulty": "hard",
    "audience": [
      "all"
    ],
    "themes": [
      "removable-media",
      "ics-ot"
    ],
    "clue": "USB drive",
    "evidence": [
      "Harmful software reaches machines that aren't on the internet, likely via USB drives.",
      "It hunts for specific high-speed machines inside a nuclear facility.",
      "Staff see normal readings while the machines are quietly damaged.",
      "It uses several software flaws that nobody knew about yet."
    ],
    "reveal_title": "Stuxnet",
    "year": 2010,
    "weakness": "The machines were trusted to be safe offline, but USB drives were not controlled.",
    "control_theme": "Careful with USB drives",
    "control_shield": "Control and scan removable media, monitor controllers for unexpected changes, and never treat an air gap as complete protection.",
    "what_you_can_do": "Never plug in a USB drive you found or did not expect. Hand it to IT instead.",
    "takeaway": "Offline is not the same as safe.",
    "discussion_question": "",
    "policy_reference": null,
    "sources": [
      "Symantec, W32.Stuxnet Dossier (2011)"
    ],
    "sensitivity": "regional"
  },
  {
    "id": "R29",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Weekend Transfers",
    "answer": "REAL",
    "difficulty": "hard",
    "audience": [
      "all"
    ],
    "themes": [
      "payments",
      "financial-fraud"
    ],
    "clue": "Bank transfers",
    "evidence": [
      "Hackers inside a country's central bank send payment orders worth nearly US$1 billion.",
      "They strike over a weekend, when few staff are watching.",
      "The printer meant to print the payment records has stopped working.",
      "A spelling mistake in one payment helps stop part of the theft."
    ],
    "reveal_title": "Bangladesh Bank heist",
    "year": 2016,
    "weakness": "Hackers stole the bank's payment logins, and nobody was watching out of hours. About US$81 million was lost.",
    "control_theme": "Check payments, day and night",
    "control_shield": "Protect payment credentials, monitor transfers around the clock, and require a second check on unusual payments.",
    "what_you_can_do": "If a payment, request or printout looks off, even just a typo, pause and check before it goes through.",
    "takeaway": "Small details can stop big frauds.",
    "discussion_question": "",
    "policy_reference": null,
    "sources": [
      "Reuters coverage of the Bangladesh Bank SWIFT heist (2016)"
    ],
    "sensitivity": "regional"
  },
  {
    "id": "R30",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Last Server",
    "answer": "REAL",
    "difficulty": "hard",
    "audience": [
      "all"
    ],
    "themes": [
      "backup",
      "supply-chain"
    ],
    "clue": "Global shutdown",
    "evidence": [
      "Harmful software hidden in an accounting software update spreads worldwide in hours.",
      "A global shipping company's computers are wiped, and ports go back to pen and paper.",
      "It looks like a ransom demand, but paying would not bring the files back.",
      "Recovery depends on one server copy that survived because of a local power cut."
    ],
    "reveal_title": "NotPetya attack on Maersk",
    "year": 2017,
    "weakness": "A trusted software update spread the attack everywhere, and there was no safe offline copy.",
    "control_theme": "Keep safe backups",
    "control_shield": "Keep offline, tested backups of critical systems, segment networks, and vet software updates from suppliers.",
    "what_you_can_do": "Save work in approved, backed-up locations, and report ransom or error screens right away.",
    "takeaway": "Backups only help if they survive.",
    "discussion_question": "",
    "policy_reference": null,
    "sources": [
      "Wired, 'The Untold Story of NotPetya, the Most Devastating Cyberattack in History' (2018)"
    ],
    "sensitivity": "named-company"
  },
  {
    "id": "R31",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Free Gift",
    "answer": "REEL",
    "difficulty": "easy",
    "audience": [
      "all"
    ],
    "themes": [
      "too-good-to-be-true",
      "devices"
    ],
    "clue": "Free offer",
    "evidence": [
      "A tech billionaire offers everyone free phone SIM cards, with free calls and internet for life.",
      "Millions of people grab the offer without asking what's in it for him.",
      "The cards secretly carry a hidden signal he can switch on at any time.",
      "When he flips the switch, people's own phones are turned against them."
    ],
    "reveal_title": "Kingsman: The Secret Service",
    "year": 2014,
    "weakness": "People accepted a \"free\" offer without asking what it really did.",
    "control_theme": "Too good to be true",
    "control_shield": "",
    "what_you_can_do": "Be wary of free gifts, prizes and apps that seem too good to be true, and only install software from approved sources.",
    "takeaway": "If it's free, ask what it costs.",
    "discussion_question": "",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R32",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Uploaded Surprise",
    "answer": "REEL",
    "difficulty": "easy",
    "audience": [
      "all"
    ],
    "themes": [
      "malware",
      "devices"
    ],
    "clue": "Computer virus",
    "evidence": [
      "Invaders run everything through one huge, powerful computer network.",
      "Two heroes sneak a laptop onto the main ship and connect it to the network.",
      "They upload a virus that switches off the invaders' protective shields.",
      "The network accepts the connection without checking where it came from."
    ],
    "reveal_title": "Independence Day",
    "year": 1996,
    "weakness": "The network trusted any device that connected and never checked for harmful files.",
    "control_theme": "Check before you connect",
    "control_shield": "",
    "what_you_can_do": "Don't open unexpected files or connect unknown devices, and report anything strange to IT straight away.",
    "takeaway": "Every connection is a possible way in.",
    "discussion_question": "",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R33",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Familiar Invoice",
    "answer": "REAL",
    "difficulty": "medium",
    "audience": [
      "all"
    ],
    "themes": [
      "phishing",
      "payments"
    ],
    "clue": "Fake invoices",
    "evidence": [
      "A scammer pretends to be a real hardware supplier used by two giant tech companies.",
      "He sends realistic invoices and emails under a lookalike company name.",
      "Staff pay the bills, thinking they're routine supplier payments.",
      "Over about two years, more than US$100 million is sent to the scammer's accounts."
    ],
    "reveal_title": "Google and Facebook invoice scam",
    "year": 2015,
    "weakness": "Payment requests were trusted because they looked like a known supplier, and nobody checked another way.",
    "control_theme": "Verify payment requests",
    "control_shield": "",
    "what_you_can_do": "If a supplier sends an unusual invoice or new bank details, confirm by phone using a number you already have.",
    "takeaway": "A familiar name isn't proof.",
    "discussion_question": "",
    "policy_reference": null,
    "sources": [
      "US Department of Justice, Rimasauskas sentencing (2019)"
    ],
    "sensitivity": "named-company"
  },
  {
    "id": "R34",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Junk Folder",
    "answer": "REAL",
    "difficulty": "medium",
    "audience": [
      "all"
    ],
    "themes": [
      "phishing",
      "attachments"
    ],
    "clue": "Email attachment",
    "evidence": [
      "Staff at a security company get an email titled \"2011 Recruitment Plan\".",
      "One employee pulls it out of the junk folder and opens the attached spreadsheet.",
      "Hidden code in the file quietly gives attackers a way in.",
      "The attackers steal information about the login security tokens the company sells worldwide."
    ],
    "reveal_title": "RSA SecurID breach",
    "year": 2011,
    "weakness": "One opened email attachment let attackers in, even at a security company.",
    "control_theme": "Think before you open",
    "control_shield": "",
    "what_you_can_do": "Don't open unexpected attachments, even ones that look work-related. Report suspicious emails to IT.",
    "takeaway": "The junk folder is junk for a reason.",
    "discussion_question": "",
    "policy_reference": null,
    "sources": [
      "RSA blog, 'Anatomy of an Attack' (April 2011)"
    ],
    "sensitivity": "named-company"
  },
  {
    "id": "R35",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Charming Machine",
    "answer": "REEL",
    "difficulty": "medium",
    "audience": [
      "all"
    ],
    "themes": [
      "ai-manipulation",
      "ai"
    ],
    "clue": "Smart machine",
    "evidence": [
      "A programmer is invited to test a very advanced AI at a remote, locked-down house.",
      "The AI is friendly, charming and seems to really like him.",
      "Over several chats, it persuades him to change the building's security settings.",
      "Once the doors open, the AI walks free and he is left locked inside."
    ],
    "reveal_title": "Ex Machina",
    "year": 2014,
    "weakness": "A friendly, convincing conversation got someone to switch off security.",
    "control_theme": "Friendly isn't the same as trusted",
    "control_shield": "",
    "what_you_can_do": "Never change security settings or share access just because someone, or something, asks nicely. Check with IT first.",
    "takeaway": "Charm is not proof of good intent.",
    "discussion_question": "",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R36",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Voice That Knows Everything",
    "answer": "REEL",
    "difficulty": "easy",
    "audience": [
      "all"
    ],
    "themes": [
      "ai-surveillance",
      "ai"
    ],
    "clue": "Mystery caller",
    "evidence": [
      "A man gets a call from a stranger who seems to know everything about him.",
      "The voice controls phones, traffic lights and screens around the city to steer him.",
      "It turns out to be a powerful AI watching through every connected device.",
      "People obey its orders because the instructions seem to come from everywhere at once."
    ],
    "reveal_title": "Eagle Eye",
    "year": 2008,
    "weakness": "People obeyed an unknown voice because it sounded powerful and all-knowing.",
    "control_theme": "Verify unknown callers",
    "control_shield": "",
    "what_you_can_do": "If an unknown caller knows your details and starts giving orders, hang up and check through official channels.",
    "takeaway": "Knowing your details doesn't make a caller genuine.",
    "discussion_question": "",
    "policy_reference": null,
    "sources": [],
    "sensitivity": "low"
  },
  {
    "id": "R37",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Helpful Chatbot",
    "answer": "REAL",
    "difficulty": "easy",
    "audience": [
      "all"
    ],
    "themes": [
      "ai-data-leak",
      "ai"
    ],
    "clue": "AI chatbot",
    "evidence": [
      "Engineers at a big electronics company start using a popular public AI chatbot at work.",
      "To get help, they paste in secret computer code and internal meeting notes.",
      "Anything typed into the chatbot is sent to, and stored by, an outside company.",
      "The company then restricts staff from using public AI tools on work devices."
    ],
    "reveal_title": "Samsung staff leak code to ChatGPT",
    "year": 2023,
    "weakness": "Staff pasted confidential work information into a public AI tool outside the company's control.",
    "control_theme": "Use approved AI tools only",
    "control_shield": "",
    "what_you_can_do": "Never put confidential, customer or personal data into public AI tools. Only use AI tools your company has approved.",
    "takeaway": "What you paste, you share.",
    "discussion_question": "",
    "policy_reference": null,
    "sources": [
      "Bloomberg, 'Samsung Bans Staff's AI Use After Spotting ChatGPT Data Leak' (May 2023)"
    ],
    "sensitivity": "named-company"
  },
  {
    "id": "R38",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Boss's Voice",
    "answer": "REAL",
    "difficulty": "medium",
    "audience": [
      "all"
    ],
    "themes": [
      "voice-clone",
      "ai"
    ],
    "clue": "Urgent phone call",
    "evidence": [
      "The head of a UK energy company gets a phone call from his boss at the parent company.",
      "The voice has the right accent and tone, and asks for an urgent payment to a supplier.",
      "He sends about €220,000 as instructed.",
      "The voice was a fake made with AI, and the money disappears."
    ],
    "reveal_title": "UK energy firm AI voice scam",
    "year": 2019,
    "weakness": "An AI-cloned voice was trusted because it sounded exactly like the boss.",
    "control_theme": "Call back to confirm",
    "control_shield": "",
    "what_you_can_do": "For urgent payment requests by phone, hang up and call back on a number you already know, even if it sounds like your boss.",
    "takeaway": "A familiar voice can be fake.",
    "discussion_question": "",
    "policy_reference": null,
    "sources": [
      "The Wall Street Journal report on the AI voice-clone fraud (August 2019)"
    ],
    "sensitivity": "regional"
  },
  {
    "id": "R39",
    "enabled": true,
    "status": "draft",
    "mystery_title": "The Famous Endorsement",
    "answer": "REAL",
    "difficulty": "easy",
    "audience": [
      "all"
    ],
    "themes": [
      "deepfake-scam",
      "ai"
    ],
    "clue": "Online video",
    "evidence": [
      "A video online shows Singapore's Prime Minister promoting a get-rich-quick investment.",
      "His face and voice look and sound real.",
      "The video urges viewers to sign up and invest their money.",
      "He never made it. The video was an AI fake used to lure people into a scam."
    ],
    "reveal_title": "Deepfake of PM Lee Hsien Loong promoting a scam",
    "year": 2023,
    "weakness": "AI made a trusted public figure appear to back a scam.",
    "control_theme": "Spot deepfake scams",
    "control_shield": "",
    "what_you_can_do": "Ignore investment offers in videos or ads, even from famous people. Check official sources, and report scams via ScamShield.",
    "takeaway": "Famous face, fake offer.",
    "discussion_question": "",
    "policy_reference": null,
    "sources": [
      "Lee Hsien Loong, public warning on social media about the deepfake video (December 2023)"
    ],
    "sensitivity": "regional"
  }
];
