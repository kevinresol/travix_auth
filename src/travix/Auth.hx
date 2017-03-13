package travix;

import tink.Cli;
import tink.cli.Rest;
import haxe.remoting.*;
import haxe.crypto.*;
import sys.io.*;

using tink.CoreApi;

class Auth {
	
	@:required
	public var repo:String;
	
	public function new() {
		
	}
	
	@:defaultCommand
	public function help() {
		Sys.println(Cli.getDoc(this));
	}
	
	@:command
	public function encrypt(rest:Rest<String>):Promise<Noise> {
		switch rest.asArray() {
			case []: return new Error('Missing username');
			case [_]: return new Error('Missing password');
			default:
				trace(Sys.getEnv('PATH'));
				var username = rest[0];
				var password = Md5.encode(rest[1]);
				var cnx = HttpConnection.urlConnect('http://lib.haxe.org/api/3.0/index.n');
				var valid = cnx.api.checkPassword.call([username, password]); // https://github.com/HaxeFoundation/haxelib/blob/302160b/src/haxelib/SiteApi.hx#L34
				if(valid) {
					var proc = new Process('cmd', ['/c', 'travis encrypt HAXELIB_AUTH=$username:$password -r $repo']);
					switch proc.exitCode() {
						case 0:
							var entry = proc.stdout.readAll().toString();
							trace(entry);
						case c:
							trace(proc.stdout.readAll().toString());
							trace(proc.stderr.readAll().toString());
							trace(c);
							return new Error('Failed to encrypt the Travis enviroment variable');
					}
				}
		}
		
		return Noise;
	}
	
	static function main() {
		var args = Sys.args();
		#if interp Sys.setCwd(args.pop()); #end
		Cli.process(args, new Auth()).handle(Cli.exit);
	}
}