# (c) 2016, Wesley Dawson <whd(at)mozilla.com>
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

from ansible.errors import AnsibleError
from ansible.plugins.lookup import LookupBase

try:
    from boto import ec2, emr
except ImportError:
    raise AnsibleError(
        "Can't LOOKUP(emr_master_instance_id): module boto is not installed")


class LookupModule(LookupBase):

    def __init__(self, basedir=None, **kwargs):
        self.basedir = basedir

    def run(self, terms, inject=None, **kwargs):
        region, cluster_id = terms
        dns = emr.connect_to_region(
            region).describe_cluster(cluster_id).masterpublicdnsname
        return [ec2.connect_to_region(
            region).get_all_instances(
                filters={"dns-name": dns})[0].instances[0].id]
