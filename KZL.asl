/*	
PPSSPP detection code and general script skeleton credited to: https://github.com/NABN00B/LiveSplit.Autosplitters/blob/master/LiveSplit.PPSSPP.GTA-LCS.asl
 */

// 64-bit exe only.
state("PPSSPPWindows64", "unknown") { }
state("PPSSPPWindows64", "detected") { }


startup
{
	// INITIAL SETUP
	// Reduce CPU usage.
	refreshRate = 1000/30;
	
	// Initialise variables used for emulator version control.
	version = "unknown";
	vars.EmulatorVersion = "unknown";
	vars.OffsetToGame = 0x0;
	
	// Initialise debug output functions.
	Action<string, IntPtr> DebugOutputSigScan = (source, ptr) =>
	{
		//print(String.Format("{0} {1}\n{0} ResultPointer: 0x{2:X}", "[KZL Autosplitter]", source, (long)ptr));
	};
	vars.DebugOutputSigScan = DebugOutputSigScan;
	
	Action<string> DebugOutputVersion = (source) =>
	{
		//print(String.Format("{0} {1}\n{0} EmulatorVersion: {2}, OffsetToGame: 0x{3:X}, (StateDescriptor: {4})", "[KZL Autosplitter]", source, vars.EmulatorVersion, vars.OffsetToGame, version));
	};
	vars.DebugOutputVersion = DebugOutputVersion;
	
	
	Action<string> DebugOutputVars = (source) =>
	{
		//print(String.Format("{0} {1}\n{0} SplitPrevention: {2}\n{0} SplitMissionStart: {3}\n{0} SplitRampageStart: {4}\n{0} SplitStauntonReached: {5}\n{0} SplitShoresideReached: {6}", "[KZL Autosplitter]", source, vars.SplitPrevention.ToString(), vars.SplitMissionStart.ToString(), vars.SplitRampageStart.ToString(), vars.SplitStauntonReached.ToString(), vars.SplitShoresideReached.ToString()));
	};
	vars.DebugOutputVars = DebugOutputVars;
	
	// INITIAL SETUP END
	
	// SETTINGS

	// SETTINGS END
}

init
{
	// EMULATOR VERSION CONTROL
	vars.DebugOutputVersion("INIT - DETECTING EMULATOR VERSION...");
	// Scan for the signature of `static int sceMpegRingbufferAvailableSize(u32 ringbufferAddr)` to get the address that's 22 bytes off the instruction that accesses the memory pointer.
	var page = modules.First();
    var scanner = new SignatureScanner(game, page.BaseAddress, page.ModuleMemorySize);
    IntPtr ptr = scanner.Scan(new SigScanTarget(22, "41 B9 ?? 05 00 00 48 89 44 24 20 8D 4A FC E8 ?? ?? ?? FF 48 8B 0D ?? ?? ?? 00 48 03 CB"));
	vars.DebugOutputSigScan("INIT - BASE OFFSET SIGSCAN", ptr);
	
	if (ptr != IntPtr.Zero)
	{
		vars.OffsetToGame = (int) ((long)ptr - (long)page.BaseAddress + game.ReadValue<int>(ptr) + 0x4);
		version = "detected";
		vars.EmulatorVersion = modules.First().FileVersionInfo.FileVersion;
	}
	else
	{
		// Switch to manual version detection if the signature scan fails.
		switch (modules.First().FileVersionInfo.FileVersion)	
		{
			// Add new versions to the top.
			case "v1.10.3" : version = "detected"; vars.EmulatorVersion = "v1.10.3"; vars.OffsetToGame = 0xC54CB0; break;
			case "v1.10.2" : version = "detected"; vars.EmulatorVersion = "v1.10.2"; vars.OffsetToGame = 0xC53CB0; break;
			case "v1.10.1" : version = "detected"; vars.EmulatorVersion = "v1.10.1"; vars.OffsetToGame = 0xC53B00; break;
			case "v1.10"   : version = "detected"; vars.EmulatorVersion = "v1.10"  ; vars.OffsetToGame = 0xC53AC0; break;
			case "v1.9.3"  : version = "detected"; vars.EmulatorVersion = "v1.9.3" ; vars.OffsetToGame = 0xD8C010; break;
			case "v1.9"    : version = "detected"; vars.EmulatorVersion = "v1.9"   ; vars.OffsetToGame = 0xD8AF70; break;
			case "v1.8.0"  : version = "detected"; vars.EmulatorVersion = "v1.8.0" ; vars.OffsetToGame = 0xDC8FB0; break;
			case "v1.7.4"  : version = "detected"; vars.EmulatorVersion = "v1.7.4" ; vars.OffsetToGame = 0xD91250; break;
			case "v1.7.1"  : version = "detected"; vars.EmulatorVersion = "v1.7.1" ; vars.OffsetToGame = 0xD91250; break;
			case "v1.7"    : version = "detected"; vars.EmulatorVersion = "v1.7"   ; vars.OffsetToGame = 0xD90250; break;
			default        : version = "unknown" ; vars.EmulatorVersion = "unknown"; vars.OffsetToGame = 0x0     ; break;
		}
	}
	vars.DebugOutputVersion("INIT - EMULATOR VERSION DETECTED");
	// EMULATOR VERSION CONTROL END
	
	// MEMORY WATCHERS
	if (vars.EmulatorVersion != "unknown")
	{
		vars.MemoryWatchers = new MemoryWatcherList();
		vars.ExportWatchers = new MemoryWatcherList();
		
		// Game Variables, General
		vars.MemoryWatchers.Add(new MemoryWatcher<int>(new DeepPointer(vars.OffsetToGame, 0x8E85988)) { Name = "MissionNumber" });
		
	}
	// MEMORY WATCHERS END
}

exit
{
	// Set emulator version to unrecognised.
	version = "unknown";
	vars.EmulatorVersion = "unknown";
	vars.OffsetToGame = 0x0;
	
	vars.DebugOutputVersion("EXIT");
	vars.DebugOutputVars("EXIT");
}

update
{
	// Prevent undefined functionality if emulator version is not recognised.
	if (vars.EmulatorVersion == "unknown")
	{
		vars.DebugOutputVersion("UNKNOWN EMULATOR VERSION");
		return false;
	}
	
	// Update Memory Watchers to get the new values of the emulator/game variables.
	vars.MemoryWatchers.UpdateAll(game);
	vars.ExportWatchers.UpdateAll(game);
	
	print("CURRENT MISSION NUMBER: " + vars.MemoryWatchers["MissionNumber"].Current.ToString());
}

split
{
	if (vars.MemoryWatchers["MissionNumber"].Current > vars.MemoryWatchers["MissionNumber"].Old)
		return true;
}

reset
{

}

start
{
	
}
