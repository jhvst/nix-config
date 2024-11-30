{ config
, pkgs
, ...
}:
{
  options = { };
  config = {
    programs.git = {
      enable = true;
      lfs.enable = true;
      config = {
        commit.gpgsign = true;
        gpg.format = "ssh";
        gpg.ssh.program = "${pkgs.openssh}/bin/ssh-keygen";
        tag.gpgsign = true;
        user.signingkey = "/home/juuso/.ssh/id_ed25519_sk_rk_starlabs";
        user.name = "Juuso Haavisto";
        user.email = "juuso@ponkila.com";
        http.postbuffer = 524288000; # https://stackoverflow.com/questions/22369200/git-pull-push-error-rpc-failed-result-22-http-code-408
        push.autosetupremote = true;
      };
    };
  };
}
