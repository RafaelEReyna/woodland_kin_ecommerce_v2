import { defineCollection, z } from "astro:content";

const designs = defineCollection({
  type: "content",
  schema: z.object({
    name: z.string(),
    story: z.string(),
    featured_image: z.string(),
    active: z.boolean().default(true),
    order: z.number(),
  }),
});

export const collections = { designs };
