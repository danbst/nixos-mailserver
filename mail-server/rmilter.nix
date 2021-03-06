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

{ domain, virus_scanning, dkim_signing, dkim_dir, dkim_selector }:

let
  clamav = if virus_scanning
           then
           ''
             clamav {
               servers = /var/run/clamav/clamd.ctl;
             };
           ''
           else "";
  dkim = if dkim_signing
         then
         ''
            dkim {
              domain {
                key = "${dkim_dir}";
                domain = "*";
                selector = "${dkim_selector}";
              };
              sign_alg = sha256;
              auth_only = yes;
            }
         ''
         else "";
in
{
  enable = true;
  # debug = true;
  postfix.enable = true;
  rspamd.enable = true;
  extraConfig =
  ''
    ${clamav}

    ${dkim}
  '';
}

