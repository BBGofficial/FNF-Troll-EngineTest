package;

import Discord.DiscordClient;
import sys.io.File;
import sys.FileSystem;
import flixel.text.FlxText;
import Song;

using StringTools;

class SongSelectState extends MusicBeatState
{	
	var songMeta:Array<SongMetadata> = [];
	var songText:Array<FlxText> = [];
	var curSel(default, set):Int;
	function set_curSel(sowy){
		if (songMeta.length == 0)
			return curSel = 0;

		if (sowy < 0 || sowy >= songMeta.length)
			sowy = sowy % songMeta.length;
		if (sowy < 0)
			sowy = songMeta.length + sowy;
		
		////
		var prevText = songText[curSel];
		if (prevText != null)
			prevText.color = 0xFFFFFFFF;

		var selText = songText[sowy];
		if (selText != null)
			selText.color = 0xFFFFFF00;

		////
		curSel = sowy;
		return curSel;
	}
	

	var verticalLimit:Int;

	override public function create() 
	{
		StartupState.load();

		DiscordClient.changePresence("In the Menus", null);
		FlxG.camera.bgColor = 0xFF000000;

		if (FlxG.sound.music == null)
			MusicBeatState.playMenuMusic(1);

		var folder = 'assets/songs/';
		Paths.iterateDirectory(folder, function(path:String){
			if (FileSystem.isDirectory(folder + path))
				songMeta.push(new SongMetadata(path));
		});

		#if MODS_ALLOWED
		for (modDir in Paths.getModDirectories()){
			var folder = Paths.mods('$modDir/songs/');
			Paths.iterateDirectory(folder, function(path:String){
				if (FileSystem.isDirectory(folder+path))
					songMeta.push(new SongMetadata(path, modDir));
			});
		}
		#end

		var border = 8;
		var spacing = 2;
		var textSize = 16;
		var width = 16*textSize;

		var ySpace = (textSize+spacing);

		verticalLimit = Math.floor((FlxG.height - border*2)/ySpace);

		for (id in 0...songMeta.length)
		{
			var text = new FlxText(
				border + (Math.floor(id/verticalLimit) * width), 
				border + (ySpace*(id%verticalLimit)), 
				width, 
				songMeta[id].songName,
				textSize
			);
			songText.push(text);
			add(text);
		}

		curSel = 0;

		super.create();
	}

	var xSecsHolding = 0.0;
	var ySecsHolding = 0.0; 

	override public function update(e)
	{
		var speed = 1;

		if (controls.UI_DOWN_P){
			curSel += speed;
			ySecsHolding = 0;
		}
		if (controls.UI_UP_P){
			curSel -= speed;
			ySecsHolding = 0;
		}

		if (controls.UI_UP || controls.UI_DOWN){
			var checkLastHold:Int = Math.floor((ySecsHolding - 0.5) * 10);
			ySecsHolding += e;
			var checkNewHold:Int = Math.floor((ySecsHolding - 0.5) * 10);

			if(ySecsHolding > 0.35 && checkNewHold - checkLastHold > 0)
				curSel += (checkNewHold - checkLastHold) * (controls.UI_UP ? -speed : speed);
		}

		if (controls.UI_RIGHT_P){
			curSel += verticalLimit;
			ySecsHolding = 0;
		}
		if (controls.UI_LEFT_P){
			curSel -= verticalLimit;
			ySecsHolding = 0;
		}

		if (controls.UI_LEFT || controls.UI_RIGHT){
			var checkLastHold:Int = Math.floor((ySecsHolding - 0.5) * 10);
			ySecsHolding += e;
			var checkNewHold:Int = Math.floor((ySecsHolding - 0.5) * 10);

			if(ySecsHolding > 0.35 && checkNewHold - checkLastHold > 0)
				curSel += (checkNewHold - checkLastHold) * (controls.UI_UP ? -verticalLimit : verticalLimit);
		}

		if (controls.ACCEPT){
			var charts = SongChartSelec.getCharts(songMeta[curSel]);

			trace(charts);
			
			if (charts.length > 1)
				MusicBeatState.switchState(new SongChartSelec(songMeta[curSel], charts));
			else
				Song.playSong(songMeta[curSel], charts[0], 0);
		}
        else if (controls.BACK)
            MusicBeatState.switchState(new MainMenuState());
		else if (FlxG.keys.justPressed.SEVEN)
			MusicBeatState.switchState(new editors.MasterEditorMenu());

		super.update(e);
	}
}

class SongChartSelec extends MusicBeatState
{
	var songMeta:SongMetadata;
	var alts:Array<String>;

	var texts:Array<FlxText> = [];

	var curSel = 0;

	function changeSel(diff:Int = 0)
	{
		texts[curSel].color = 0xFFFFFFFF;

		curSel += diff;
		
		if (curSel < 0)
			curSel += alts.length;
		else if (curSel >= alts.length)
			curSel -= alts.length;

		texts[curSel].color = 0xFFFFFF00;
	}

	override function create()
	{
		add(new FlxText(0, 5, FlxG.width, songMeta.songName).setFormat(null, 20, 0xFFFFFFFF, CENTER));

		for (id in 0...alts.length){
			var alt = alts[id];
			var text = new FlxText(20, 20 + id * 20 , (FlxG.width-20) / 2, alt, 16);

			// uhhh we don't save separate highscores for other chart difficulties oops
			// var scoreTxt = new FlxText(text.x + text.width, text.y, text.fieldWidth, Highscore.getScore(songMeta.songName));

			texts[id] = text;

			add(text);
		}

		changeSel();
	}

	override public function update(e){
		if (controls.UI_DOWN_P)
			changeSel(1);
		if (controls.UI_UP_P)
			changeSel(-1);

		if (controls.BACK)
			MusicBeatState.switchState(new FreeplayState());
		else if (controls.ACCEPT){
			var daDiff = alts[curSel];
			Song.playSong(songMeta, (daDiff=="normal") ? null : daDiff, curSel);
		}

		super.update(e);
	} 

	public function new(WHO:SongMetadata, alts) 
	{
		super();
		
		songMeta = WHO;
		this.alts = alts;
	}

	public static function getCharts(metadata:SongMetadata)
	{
		Paths.currentModDirectory = metadata.folder;

		var songName = Paths.formatToSongPath(metadata.songName);
		var folder = (metadata.folder=="") ? Paths.getPath('songs/$songName/') : Paths.mods('${metadata.folder}/songs/$songName/');

		trace(songName, folder);

		var alts = [];

		Paths.iterateDirectory(folder, function(fileName){
			if (fileName == '$songName.json'){
				alts.insert(1, "normal");
				return;		
			}
			
			if (!fileName.startsWith('$songName-') || !fileName.endsWith('.json'))
				return;

			var prefixLength = songName.length + 1;
			alts.push(fileName.substr(prefixLength, fileName.length - prefixLength - 5));
		});

		return alts;
	} 
}