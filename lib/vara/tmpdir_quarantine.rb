# Some BOSH code messes with $TMPDIR as a side effect. This stops
# that from messing everything else up.
#
# Issue: https://github.com/cloudfoundry/bosh/issues/480
def quarantine_tmpdir_code
  tmp = ENV['TMPDIR']
  yield
  ENV['TMPDIR'] = tmp
end
