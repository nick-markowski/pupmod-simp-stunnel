require 'spec_helper_acceptance'

test_name 'individual_connection'

describe 'individual_connection' do
  hosts.each do |host|

    # This test verifys the validity of basic stunnel configurations
    # and ensures multiple connections can co-exist as advertised. It
    # does not test stunnel itself.
    context 'set up two connections' do
      let(:manifest) { <<EOF
stunnel::standalone{ 'nfs':
  client       => false,
  connect      => [2049],
  accept       => 20490,
}
stunnel::connection{ 'rsync':
  client       => false,
  connect      => [3049],
  accept       => 30490
}
EOF
      }
      let(:hieradata) {{
        'simp_options::pki'          => true,
        'simp_options::pki::source'  => '/etc/pki/simp-testing/pki/',
        'simp_options::trusted_nets' => ['any']
      }}

      it 'should work with no errors' do
        set_hieradata_on(host,hieradata)
        apply_manifest_on(host,manifest,:catch_failures => true)
      end

      it 'should be running stunnel and stunnel_nfs' do
        if fact_on(host, 'operatingsystemmajrelease').to_s >= '7'
          on(host, 'systemctl status stunnel', :acceptable_exit_codes => 0)
          on(host, 'systemctl status stunnel_nfs', :acceptable_exit_codes => 0)
        else
          on(host, 'service stunnel status', :acceptable_exit_codes => 0)
          on(host, 'service stunnel_nfs status', :acceptable_exit_codes => 0)
        end
      end

      it 'stunnel_nfs should be listening on 20490' do
        pid = on(host, 'cat /var/run/stunnel/stunnel_nfs.pid').stdout.strip
        result = on(host, "netstat -plant | grep #{pid} | awk ' { print $4 }'").stdout.strip
        expect(result).to match(/0.0.0.0:20490/)
      end

      # TODO: Add test to ensure stunnel was chkconfig'd

    end
  end
end