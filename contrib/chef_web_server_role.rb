name        "web_server"
description "A web server."

run_list(
  "recipe[apache2]",
  "recipe[chef-client]",
  "recipe[chef-client::delete_validation]",
)

override_attributes(
  'chef_client' => {
    'server_url' => "http://chef.razornet.local",
    'validation_client_name' => "chef-validator"
  }
)
