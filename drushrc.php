<?php

exec('git rev-parse --git-dir 2> /dev/null', $output);
if (!empty($output)) {
  $repo = $output[0];
  $options['config'] = $repo . '/../drush/drushrc.php';
  $options['include'] = array($repo . '/../drush/commands', $repo . '/../drush/modules');
  $options['alias-path'] = $repo . '/../drush/aliases';
}
