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
	
	public var add:String;
	
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
		var cwd = Sys.getCwd();
		var cnx = HttpConnection.urlConnect('http://lib.haxe.org/api/3.0/index.n');
		
		// https://github.com/HaxeFoundation/haxelib/blob/302160b/src/haxelib/SiteApi.hx#L34
		if(cnx.api.checkPassword.call([username, Md5.encode(password)])) {
			switch which(isWindows ? 'travis.bat' : 'travis') {
				case Success(path):
					var args = ['encrypt', 'HAXELIB_AUTH=$username:$password', '-r', repo];
					if(add != null) args = args.concat(['--add', add]);
					switch run(path, args) {
						case Success(v):
							if(isWindows) Sys.setCwd(cwd);
							Sys.println(add != null ? 'Added secure variable entry to $add in .travis.yml' : v);
						case Failure(e):
							return Error.withData('Cannot encrypt variable', e.data); 
					}
				case Failure(_):
					return new Error('travis not installed. Install instructions can be found here: <url>');
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