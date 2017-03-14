package travix;

import tink.Cli;
import tink.cli.Rest;
import haxe.remoting.*;
import haxe.crypto.*;
import sys.io.*;

using haxe.io.Path;
using tink.CoreApi;

/**
 *  Handy little tool for generating secure environment variables that stores haxelib credentials. To be used with the travix tool.
 */
class Auth {
	
	/**
	 *  Github repo in the form of <owner>/<repo>. Example: back2dos/travix
	 */
	@:required
	public var repo:String;
	
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
	public function encrypt(rest:Rest<String>):Promise<Noise> {
		switch rest.asArray() {
			case []: return new Error('Missing username');
			case [_]: return new Error('Missing password');
			default:
				var username = rest[0];
				var password = Md5.encode(rest[1]);
				var cnx = HttpConnection.urlConnect('http://lib.haxe.org/api/3.0/index.n');
				var valid = cnx.api.checkPassword.call([username, password]); // https://github.com/HaxeFoundation/haxelib/blob/302160b/src/haxelib/SiteApi.hx#L34
				if(valid) {
					var args = ['encrypt', 'HAXELIB_AUTH=$username:$password', '-r', repo];
					var encrypted = 
						if(isWindows) {
							// strange ruby behaviour on windows, when running the process from haxe:
							// somehow the ruby expects the gem to be located at cwd
							// so we switch to the folder containing the gem before running it
							switch run('where', ['travis.bat']) {
								case Success(path):
									var path = path.split('\r\n')[0];
									var folder = path.directory();
									var cwd = Sys.getCwd();
									Sys.setCwd(folder);
									switch run('travis.bat', args) {
										case Success(v):
											Sys.setCwd(cwd);
											v;
										case Failure(e):
											return Error.withData('Cannot encrypt variable', e.data); 
									}
								case Failure(e):
									return new Error('travis not installed');
							}
						} else {
							switch run('which', ['travis']) {
								case Success(_):
									switch run('travis', args) {
										case Success(v): v;
										case Failure(e): return Error.withData('Cannot encrypt variable', e.data); 
									}
								case Failure(_):
									return new Error('travis not installed');
							}
						}
					trace('  - secure: ' + encrypted);
				} else {
					return new Error('Incorrect haxelib credentials');
				}
		}
		
		return Noise;
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