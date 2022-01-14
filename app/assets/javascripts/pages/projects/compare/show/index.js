import Diff from '~/diff';
import GpgBadges from '~/gpg_badges';
import { initDiffStatsDropdown } from '~/init_diff_stats_dropdown';
import initCompareSelector from '~/projects/compare';

initCompareSelector();

new Diff(); // eslint-disable-line no-new
const paddingTop = 16;
initDiffStatsDropdown(document.querySelector('.navbar-gitlab').offsetHeight - paddingTop);
GpgBadges.fetch();
