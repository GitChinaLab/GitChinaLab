import $ from 'jquery';
import docs from '~/docs/docs_bundle';
import VersionCheckImage from '~/version_check_image';

docs();
VersionCheckImage.bindErrorEvent($('img.js-version-status-badge'));
