
const BASIC_USER = 'juuso';
const BASIC_PASS = '';

/**
 * Many more examples available at:
 *   https://developers.cloudflare.com/workers/examples
 * @param {Request} request
 * @returns {Promise<Response>}
 */
async function handleRequest(request) {
  const { protocol, pathname } = new URL(request.url);

  switch (pathname) {

    case '/intra/vultr-stockholm-1/bzImage': {
      if (request.headers.has('Authorization')) {
        // Throws exception when authorization fails.
        const { user, pass } = basicAuthentication(request);
        verifyCredentials(user, pass);
        return fetch("http://${user}:${pass}@boot.ponkila.com/intra/vultr-stockholm-1/bzImage");
      };

      return new Response('You need to login.', {
        status: 401,
        headers: {
          // Prompts the user for credentials.
          'WWW-Authenticate': 'Basic realm="my scope", charset="UTF-8"',
        },
      });
    };

    case '/intra/vultr-stockholm-1/initrd.gz': {
      if (request.headers.has('Authorization')) {
        // Throws exception when authorization fails.
        const { user, pass } = basicAuthentication(request);
        verifyCredentials(user, pass);
        return fetch("http://${user}:${pass}@boot.ponkila.com/intra/vultr-stockholm-1/initrd.gz");
      };

      return new Response('You need to login.', {
        status: 401,
        headers: {
          // Prompts the user for credentials.
          'WWW-Authenticate': 'Basic realm="my scope", charset="UTF-8"',
        },
      });
    };

    case '/intra/login': {
        return new Response(`#!ipxe

          set menu-timeout 0
          login

          chain http://\${username:uristring}:\${password:uristring}@boot.ponkila.com/intra/menu.ipxe
        `, {
          status: 200,
          headers: {
            'Cache-Control': 'no-store',
          },
        });
    };

    case '/intra/menu.ipxe': {
      // The "Authorization" header is sent when authenticated.
      if (request.headers.has('Authorization')) {
        // Throws exception when authorization fails.
        const { user, pass } = basicAuthentication(request);
        verifyCredentials(user, pass);

        // Only returns this response when no exception is thrown.
        return new Response(`#!ipxe

          set menu-timeout 0
          login

          ############################ MAIN MENU ################################
          :start
          menu iPXE Boot Menu
          item
          item --gap --           ---------------- Operating Systems ----------------
          item --key 1 nix        [1] vultr-stockholm-1
          item --gap --           ---------------- Advanced Options -----------------
          item --gap --           ---------------- Advanced Options -----------------
          item --gap --           ---------------- Advanced Options -----------------
          item --key c config                     [c] Configure Settings
          item --key s shell                      [s] Enter iPxe Shell
          item --key r reboot                     [r] Reboot computer

          ############################## Main ITEMS ##############################

          :nix
          kernel http://${user}:${pass}@boot.ponkila.com/intra/vultr-stockholm-1/bzImage init=/nix/store/c3vx5x49b4af73mxfjgq1nmrx22zzn9d-nixos-system-tuk1-23.05pre-git/init initrd=initrd zram.num_devices=1 loglevel=4
          initrd http://${user}:${pass}@boot.ponkila.com/intra/vultr-stockholm-1/initrd.gz
          boot

          :shell
          echo Type 'exit' to get back
          shell
          set menu-timeout 0
          goto start

          :failed
          echo Booting failed, dropping to shell
          goto shell

          :reboot
          reboot

          :config
          config
          goto start
        `, {
          status: 200,
          headers: {
            'Cache-Control': 'no-store',
          },
        });
      }

      return new Response('You need to login.', {
        status: 401,
        headers: {
          // Prompts the user for credentials.
          'WWW-Authenticate': 'Basic realm="my scope", charset="UTF-8"',
        },
      });
    };
  }

  return new Response('You need to login.', {
    status: 401,
    headers: {
      // Prompts the user for credentials.
      'WWW-Authenticate': 'Basic realm="my scope", charset="UTF-8"',
    },
  });
}

/**
 * Throws exception on verification failure.
 * @param {string} user
 * @param {string} pass
 * @throws {UnauthorizedException}
 */
function verifyCredentials(user, pass) {
  if (BASIC_USER !== user) {
    throw new UnauthorizedException('Invalid credentials.');
  }

  if (BASIC_PASS !== pass) {
    throw new UnauthorizedException('Invalid credentials.');
  }
}

/**
 * Parse HTTP Basic Authorization value.
 * @param {Request} request
 * @throws {BadRequestException}
 * @returns {{ user: string, pass: string }}
 */
function basicAuthentication(request) {
  const Authorization = request.headers.get('Authorization');

  const [scheme, encoded] = Authorization.split(' ');

  // The Authorization header must start with Basic, followed by a space.
  if (!encoded || scheme !== 'Basic') {
    throw new BadRequestException('Malformed authorization header.');
  }

  // Decodes the base64 value and performs unicode normalization.
  // @see https://datatracker.ietf.org/doc/html/rfc7613#section-3.3.2 (and #section-4.2.2)
  // @see https://dev.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/String/normalize
  const buffer = Uint8Array.from(atob(encoded), character => character.charCodeAt(0));
  const decoded = new TextDecoder().decode(buffer).normalize();

  // The username & password are split by the first colon.
  //=> example: "username:password"
  const index = decoded.indexOf(':');

  // The user & password are split by the first colon and MUST NOT contain control characters.
  // @see https://tools.ietf.org/html/rfc5234#appendix-B.1 (=> "CTL = %x00-1F / %x7F")
  if (index === -1 || /[\0-\x1F\x7F]/.test(decoded)) {
    throw new BadRequestException('Invalid authorization value.');
  }

  return {
    user: decoded.substring(0, index),
    pass: decoded.substring(index + 1),
  };
}

function UnauthorizedException(reason) {
  this.status = 401;
  this.statusText = 'Unauthorized';
  this.reason = reason;
}

function BadRequestException(reason) {
  this.status = 400;
  this.statusText = 'Bad Request';
  this.reason = reason;
}

addEventListener('fetch', event => {
  event.respondWith(
    handleRequest(event.request).catch(err => {
      const message = err.reason || err.stack || 'Unknown Error';

      return new Response(message, {
        status: err.status || 500,
        statusText: err.statusText || null,
        headers: {
          'Content-Type': 'application/octet-stream',
          // Disables caching by default.
          'Cache-Control': 'no-store',
          // Returns the "Content-Length" header for HTTP HEAD requests.
          'Content-Length': message.length,
        },
      });
    })
  );
});
