Puppet::Type.newtype(:elasticsearch-legacy_user_roles) do
  desc 'Type to model elasticsearch-legacy user roles.'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'User name.'
  end

  newproperty(:roles, :array_matching => :all) do
    desc 'Array of roles that the user should belong to.'
    def insync? is
      is.sort == should.sort
    end
  end

  autorequire(:elasticsearch-legacy_user) do
    self[:name]
  end
end
