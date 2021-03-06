#  nixos-mailserver: a simple mail server
#  Copyright (C) 2016-2017  Robin Raymond
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program. If not, see <http://www.gnu.org/licenses/>

{ config, pkgs, ... }:

let

  #
  # The domain that this mail server serves. So far only one domain is supported
  #
  domain = "example.com";

  #
  # The prefix of the FQDN of the server. In this example the FQDN of the server
  # is given by 'mail.example.com'
  #
  host_prefix = "mail";

  #
  # The login account of the domain. Every account is mapped to a unix user,
  # e.g. `user1@example.com`. To generate the passwords use `mkpasswd` as
  # follows
  #
  # ```
  # mkpasswd -m sha-512 "super secret password"
  # ```
  #
  login_accounts = [
    { name = "user1";
      password = "$6$evQJs5CFQyPAW09S$Cn99Y8.QjZ2IBnSu4qf1vBxDRWkaIZWOtmu1Ddsm3.H3CFpeVc0JU4llIq8HQXgeatvYhh5O33eWG3TSpjzu6/";
    }
    { name = "user2";
      password = "$6$oE0ZNv2n7Vk9gOf$9xcZWCCLGdMflIfuA0vR1Q1Xblw6RZqPrP94mEit2/81/7AKj2bqUai5yPyWE.QYPyv6wLMHZvjw3Rlg7yTCD/";
    }
  ];

  #
  # Virtual Aliases. A virtual alias { from = "info"; to = "user1"; } means that
  # all mail to `info@example.com` is forwarded to `user1@example.com`. Note
  # that it is expected that `postmaster@example.com` and `abuse@example.com` is
  # forwarded to some valid email address. (Alternatively you can create login
  # accounts for `postmaster` and (or) `abuse`).
  #
  valiases = [
    { from = "info";
      to = "user1";
    }
    { from = "postmaster";
      to = "user1";
    }
    { from = "abuse";
      to = "user1";
    }
  ];

  #
  # The unix UID where the login_accounts are created. 5000 means that the first
  # user will get 5000, the second 5001, ...
  #
  vmail_id_start = 5000;

  #
  # The user name and group name of the user that owns the directory where all
  # the mail is stored.
  #
  vmail_user_name = "vmail";
  vmail_group_name = "vmail";

  #
  # Where to store the mail.
  #
  mail_dir = "/var/vmail";

  #
  # Certificate Files. There are three options for these.
  #
  # 1) You specify locations and manually copy certificates there.
  # 2) You let the server create new (self signed) certificates on the fly.
  # 3) You let the server create a certificate via `Let's Encrypt`. Note that
  #    this implies that a stripped down webserver has to be started. This also
  #    implies that the FQDN must be set as an `A` record to point to the IP of
  #    the server. TODO: Explain more details
  #
  # TODO: Only certificate scheme 1) and 2) work as of yet.
  certificate_scheme = 2;

  # Sceme 1)
  cert_file = "/root/mail-server.crt";
  key_file = "/root/mail-server.key";

  # Sceme 2)
  # This is the folder where the certificate will be created. The name is
  # hardcoded to "cert-${domain}.pem" and "key-${domain}.pem" and the
  # certificate is valid for 10 years.
  cert_dir = "/var/certs";

  #
  # Whether to enable imap / pop3. Both variants are only supported in the
  # (sane) startTLS configuration. (TODO: Allow SSL ports). The ports are
  #
  # 110 - Pop3
  # 143 - IMAP
  # 587 - SMTP with login
  #
  enable_imap = true;
  enable_pop3 = false;
  # imap_ssl = false; #< TODO
  # pop3_ssl = false; #< TODO

  #
  # Whether to activate virus scanning. Note that virus scanning is _very_
  # expensive memory wise.
  #
  virus_scanning = false;

  #
  # Whether to activate dkim signing.
  # TODO: Explain how to put signature into domain record
  #
  dkim_signing = true;
  dkim_selector = "mail";
  dkim_dir = "/var/dkim";
in
{
  services = import ./mail-server/services.nix {
    inherit mail_dir vmail_user_name vmail_group_name valiases domain
            enable_imap enable_pop3 virus_scanning dkim_signing dkim_selector
            dkim_dir certificate_scheme cert_file key_file cert_dir;
 };

  environment = import ./mail-server/environment.nix {
    inherit pkgs certificate_scheme;
  };

  networking = import ./mail-server/networking.nix {
    inherit domain host_prefix enable_imap enable_pop3;
  };

  systemd = import ./mail-server/systemd.nix {
    inherit mail_dir vmail_group_name certificate_scheme cert_dir host_prefix
            domain pkgs dkim_selector dkim_dir;
  };

  users = import ./mail-server/users.nix {
    inherit vmail_id_start vmail_user_name vmail_group_name domain mail_dir
            login_accounts;
  };
}
