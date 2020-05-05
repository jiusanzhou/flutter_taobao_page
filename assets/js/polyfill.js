if (!Array.from) {
    Array.from = function (object) { return [].slice.call(object) };
}