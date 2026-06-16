function ts() {
  return new Date().toISOString().replace('T', ' ').slice(0, 19);
}

const log  = (label, msg) => console.log(`${ts()} [${label}] ${msg}`);
const warn = (label, msg) => console.warn(`${ts()} [${label}] ${msg}`);
const err  = (label, msg) => console.error(`${ts()} [${label}] ${msg}`);

module.exports = { log, warn, err };
