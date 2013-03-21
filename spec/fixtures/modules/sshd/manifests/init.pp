class sshd {
  file { '/etc/ssh/sshd_config':
    ensure => present,
  }

  augeas { "root login":
    context => '/files/etc/ssh/sshd_config',
    changes => 'set PermitRootLogin yes',
    require => File['/etc/ssh/sshd_config'],
  }

  augeas { "incl root login":
    incl    => '/etc/ssh/sshd_config',
    lens    => 'Sshd.lns',
    changes => 'set PermitRootLogin yes',
  }

  augeas { "add root login":
    context => '/files/etc/ssh/sshd_config',
    changes => [
      'ins PermitRootLogin after *[last()]',
      'set PermitRootLogin[last()] yes'
    ],
  }

  augeas { "fail to add root login":
    context => '/files/etc/ssh/sshd_config',
    changes => 'ins PermitRootLogin after *[last()]',
  }

  augeas { "make no change":
    context => '/files/etc/ssh/sshd_config',
    changes => 'set /foo bar',
  }
}
