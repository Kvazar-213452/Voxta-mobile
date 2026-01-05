import argon2 from "argon2";

const hash = await argon2.hash("213452");
console.log(hash)