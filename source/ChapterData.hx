package;

import haxe.Json;
import haxe.format.JsonParser;

#if sys
import sys.FileSystem;
import sys.io.File;
#else
import openfl.utils.Assets;
#end

typedef ChapterMetadata = {
	var name:String;
	var category:String;
	var unlockCondition:Dynamic;
	var songs:Array<String>;
    var directory:String;
}

class ChapterData{
	public static var chaptersList:Array<ChapterMetadata> = [];

	public static function reloadChapterFiles():Array<ChapterMetadata>
	{
		var list:Array<ChapterMetadata> = [];

		#if MODS_ALLOWED
		for (mod in Paths.getModDirectories()){
			Paths.currentModDirectory = mod;
			var path = Paths.modFolders("metadata.json");
			var rawJson:Null<String> = null;
			
			#if sys
			if (FileSystem.exists(path))
				rawJson = File.getContent(path);
			#else
			if (Assets.exists(path))
				rawJson = Assets.getText(path);
			#end

			if (rawJson != null && rawJson.length > 0)
            {
				var json = cast Json.parse(rawJson);
				json.directory = mod;
				list.push(json);
			}		
		}
		Paths.currentModDirectory = '';
        #end

		chaptersList = list;

		return list;
	}
}