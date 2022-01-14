import { memoize } from 'lodash';
import { createNodeDict } from '../utils';
import { createSankey } from './dag/drawing_utils';

/*
  A peformant alternative to lodash's isEqual. Because findIndex always finds
  the first instance of a match, if the found index is not the first, we know
  it is in fact a duplicate.
*/
const deduplicate = (item, itemIndex, arr) => {
  const foundIdx = arr.findIndex((test) => {
    return test.source === item.source && test.target === item.target;
  });

  return foundIdx === itemIndex;
};

export const makeLinksFromNodes = (nodes, nodeDict) => {
  const constantLinkValue = 10; // all links are the same weight
  return nodes
    .map(({ jobs, name: groupName }) =>
      jobs.map(({ needs = [] }) =>
        needs.reduce((acc, needed) => {
          // It's possible that we have an optional job, which
          // is being needed by another job. In that scenario,
          // the needed job doesn't exist, so we don't want to
          // create link for it.
          if (nodeDict[needed]?.name) {
            acc.push({
              source: nodeDict[needed].name,
              target: groupName,
              value: constantLinkValue,
            });
          }

          return acc;
        }, []),
      ),
    )
    .flat(2);
};

export const getAllAncestors = (nodes, nodeDict) => {
  const needs = nodes
    .map((node) => {
      return nodeDict[node]?.needs || '';
    })
    .flat()
    .filter(Boolean)
    .filter(deduplicate);

  if (needs.length) {
    return [...needs, ...getAllAncestors(needs, nodeDict)];
  }

  return [];
};

export const filterByAncestors = (links, nodeDict) =>
  links.filter(({ target, source }) => {
    /*

    for every link, check out it's target
    for every target, get the target node's needs
    then drop the current link source from that list

    call a function to get all ancestors, recursively
    is the current link's source in the list of all parents?
    then we drop this link

  */
    const targetNode = target;
    const targetNodeNeeds = nodeDict[targetNode].needs;
    const targetNodeNeedsMinusSource = targetNodeNeeds.filter((need) => need !== source);
    const allAncestors = getAllAncestors(targetNodeNeedsMinusSource, nodeDict);
    return !allAncestors.includes(source);
  });

export const parseData = (nodes) => {
  const nodeDict = createNodeDict(nodes);
  const allLinks = makeLinksFromNodes(nodes, nodeDict);
  const filteredLinks = allLinks.filter(deduplicate);
  const links = filterByAncestors(filteredLinks, nodeDict);

  return { nodes, links };
};

/*
  The number of nodes in the most populous generation drives the height of the graph.
*/

export const getMaxNodes = (nodes) => {
  const counts = nodes.reduce((acc, { layer }) => {
    if (!acc[layer]) {
      acc[layer] = 0;
    }

    acc[layer] += 1;

    return acc;
  }, []);

  return Math.max(...counts);
};

/*
  Because we cannot know if a node is part of a relationship until after we
  generate the links with createSankey, this function is used after the first call
  to find nodes that have no relations.
*/

export const removeOrphanNodes = (sankeyfiedNodes) => {
  return sankeyfiedNodes.filter((node) => node.sourceLinks.length || node.targetLinks.length);
};

/*
  This utility accepts unwrapped pipeline data in the format returned from
  our standard pipeline GraphQL query and returns a list of names by layer
  for the layer view. It can be combined with the stageLookup on the pipeline
  to generate columns by layer.
*/

export const listByLayers = ({ stages }) => {
  const arrayOfJobs = stages.flatMap(({ groups }) => groups);
  const parsedData = parseData(arrayOfJobs);
  const dataWithLayers = createSankey()(parsedData);

  const pipelineLayers = dataWithLayers.nodes.reduce((acc, { layer, name }) => {
    /* sort groups by layer */

    if (!acc[layer]) {
      acc[layer] = [];
    }

    acc[layer].push(name);

    return acc;
  }, []);

  return {
    linksData: parsedData.links,
    numGroups: arrayOfJobs.length,
    pipelineLayers,
  };
};

export const generateColumnsFromLayersListBare = ({ stages, stagesLookup }, pipelineLayers) => {
  return pipelineLayers.map((layers, idx) => {
    /*
      Look up the groups in each layer,
      then add each set of layer groups to a stage-like object.
    */

    const groups = layers.map((id) => {
      const { stageIdx, groupIdx } = stagesLookup[id];
      return stages[stageIdx]?.groups?.[groupIdx];
    });

    return {
      name: '',
      id: `layer-${idx}`,
      status: { action: null },
      groups: groups.filter(Boolean),
    };
  });
};

export const generateColumnsFromLayersListMemoized = memoize(generateColumnsFromLayersListBare);
