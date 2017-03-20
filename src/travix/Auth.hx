package travix;

import tink.Cli;
import tink.cli.Rest;
import haxe.remoting.*;
import haxe.crypto.*;
import sys.io.*;
import sys.*;

using StringTools;
using haxe.io.Path;
using tink.CoreApi;

/**
 *  Handy little tool for generating secure environment variables that stores haxelib credentials. To be used with the travix tool.
 */
class Auth {
	
	/**
	 *  Haxelib username
	 */
	@:required
	public var username:String;
	
	/**
	 *  Haxelib password
	 */
	@:required
	public var password:String;
	
	/**
	 *  Github repo in the form of <owner>/<repo>. Example: back2dos/travix
	 */
	@:required
	public var repo:String;
	
	/**
	 *  Don't add an entry to .travis.yml
	 */
	public var noadd:Bool;
	
	static var isWindows = Sys.systemName() == 'Windows';
	
	public function new() {}
	
	/** */
	@:defaultCommand @:skipFlags
	public function help() {
		Sys.println(Cli.getDoc(this));
	}
	
	/**
	 *  Encrypt haxelib credentials as travis secure environment variable
	 *  Usage: haxelib run travix_auth encrypt <haxelib_user> <haxelib_password> -r <owner>/<repo>
	 */
	@:command
	public function encrypt():Promise<Noise> {
		var cnx = HttpConnection.urlConnect('http://lib.haxe.org/api/3.0/index.n');
		
		// https://github.com/HaxeFoundation/haxelib/blob/302160b/src/haxelib/SiteApi.hx#L34
		if(cnx.api.checkPassword.call([username, Md5.encode(password)])) {
			switch which(isWindows ? 'travis.bat' : 'travis') {
				case Success(path):
					var args = ['encrypt', 'HAXELIB_AUTH=$username:$password', '-r', repo];
					switch run(path, args) {
						case Success(hash):
							if(noadd) Sys.println(hash);
							else {
								// add an entry in a not-so-robust way
								var yml = File.getContent('.travis.yml');
								var env = ~/^env:/;
								var secure = ~/secure:\s*.*/;
								var lines = yml.split('\n');
								var added = false;
								for(i in 0...lines.length) {
									if(env.match(lines[i])) {
										if(secure.match(lines[i + 1]))
											lines[i + 1] = secure.replace(lines[i + 1], 'secure: $hash');
										else
											lines.insert(i + 1, '  - secure: $hash');
										added = true;
										break;
									}
								}
								if(!added) lines.push('env:\n  - secure: $hash');
								File.saveContent('.travis.yml', lines.join('\n'));
								Sys.println('Added secure variable entry to .travis.yml');
							}
						case Failure(e):
							return Error.withData('Cannot encrypt variable', e.data); 
					}
				case Failure(_):
					return new Error('travis not installed. Install Ruby and then run `gem install travis`');
			}
			
		} else {
			return new Error('Incorrect haxelib credentials');
		}
		
		return Noise;
	}
	
	function which(cmd) {
		return run(isWindows ? 'where' : 'which', [cmd])
			.map(function(path) return path.replace('\r\n', '\n').split('\n')[0]);
	}
	
	function run(cmd, args) {
		var proc = new Process(cmd, args);
		return switch proc.exitCode() {
			case 0: Success(proc.stdout.readAll().toString());
			case c: Failure(Error.withData(c, 'Error in running: $cmd ${args.join(" ")}',  proc.stderr.readAll().toString()));
		}
	}
	
	static function main() {
		var args = Sys.args();
		#if interp Sys.setCwd(args.pop()); #end
		Cli.process(args, new Auth()).handle(Cli.exit);
	}
}