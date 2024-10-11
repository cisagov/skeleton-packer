build {
  sources = [
    "source.amazon-ebs.arm64",
    "source.amazon-ebs.x86_64",
  ]

  provisioner "ansible" {
    playbook_file = "ansible/upgrade.yml"
    use_proxy     = false
    use_sftp      = true
  }

  provisioner "ansible" {
    playbook_file = "ansible/python.yml"
    use_proxy     = false
    use_sftp      = true
  }

  provisioner "ansible" {
    ansible_env_vars = ["AWS_DEFAULT_REGION=${var.build_region}"]
    playbook_file    = "ansible/playbook.yml"
    use_proxy        = false
    use_sftp         = true
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo env {{ .Vars }} {{ .Path }} ; rm -f {{ .Path }}"
    inline          = ["sed -i '/^users:/ {N; s/users:.*/users: []/g}' /etc/cloud/cloud.cfg", "rm --force /etc/sudoers.d/90-cloud-init-users", "rm --force /root/.ssh/authorized_keys", "/usr/sbin/userdel --remove --force admin"]
    skip_clean      = true
  }
}
